#!/bin/bash
# MIT Licensed Sam Gleske (@samrocketman on GitHub)
# DESCRIPTION:
#     Search for volumes based on a tag and attach it to the AWS instance where
#     this script is run.  This assumes IAM permission to do so on the
#     instance.  If the volume is raw disk, then it will be formatted to XFS.

# EXAMPLE:
#     attach_volume.sh --volume-tags project=myproject environment=prod half=blue --owner 100:65533 --mount-path /var/lib/jenkins

set -auxeEo pipefail
export PATH="/usr/local/bin:$PATH"
type -P jq
type -P aws
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

set +x

function die() {
    echo "ERROR: $*" >&2
    exit 1
}
function usage() {
    cat <<EOF
${0##*/} --volume-tags KEY=VALUE [KEY=VALUE...] --mount-point PATH [--device PATH] [--owner CHOWN_VALUE] [--region AWS_REGION]

DESCRIPTION:
    This script will automatically:
      - find a EBS volume ID given a list of tags to match
      - attach the volume to this instance
      - format the volume to XFS only if it is raw disk
      - mount the formatted volume to a path
      - change permissions of the volume only if it was formatted
      - add an entry to /etc/fstab for auto-mounting the volume on instance
        restart

    This script is meant to be run from an instance within AWS.  The host needs
    to have the ability to search for volumes, attach volumes, and detact
    volumes.  Instances can be security scoped to only allow volumes matching a
    certain tag.

REQUIRED OPTIONS:
    --volume-tags KEY=VALUE  One or more key value pairs which will be used to
                             search volume tags to find a volume ID.

    --mount-path PATH        A destination mounting point where the volume
                             device will be mounted after it is formatted.

OPTIONAL OPTIONS:
    --device PATH            A local raw device which is the destination of the
                             attached volume.  Default is ${DEVICE_PATH}.

    --owner CHOWN_VALUE      An owner of the formated path once the volume is
                             mounted.  This supports any value that chown
                             command supports for changing ownership.
    --region AWS_REGION      An AWS region in which the aws cli will operate
                             commands on for searching the volume.
                             Alternatively, the AWS_DEFAULT_REGION environment
                             variable can be set.  The default region set is
                             us-east-1.
EOF
}

tags=()
MOUNT_PATH=""
CHOWN_VALUE=""
DEVICE_PATH="/dev/xvdf"
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        --volume-tags)
            [ -n "${2:-}" ] || die "$1 has blank or no arguments following it: $1 key=value ..."
            shift
            while grep -v -- "^--" <<< "${1:-}" | grep -F -- '=' > /dev/null; do
                tags+=( "$1" )
                shift
            done
            ;;
        --device)
            DEVICE_PATH="${2:-}"
            shift
            shift
            ;;
        --region)
            AWS_DEFAULT_REGION="${2:-}"
            shift
            shift
            ;;
        --mount-path)
            MOUNT_PATH="${2:-}"
            shift
            shift
            ;;
        --owner)
            CHOWN_VALUE="${2:-}"
            shift
            shift
            ;;
        *)
            die "ERROR: encountered invalid argument $1"
            ;;
    esac
done

[ -n "${tags[*]:-}" ] || die "--volume-tags has no arguments following it: --volume-tags key=value ..."
[ -n "${AWS_DEFAULT_REGION}" ] || die "--region AWS_REGION must be specified or set environment variable AWS_DEFAULT_REGION"
[ -n "${MOUNT_PATH}" ] || die "--mount-path PATH is a required option."

function get_volume_id() (
    local filters=()
    for tag in "$@"; do
        filters+=( "Name=tag:${tag%=*},Values=${tag#*=}" )
    done
    aws ec2 describe-volumes --filters "${filters[@]}" | jq -r '.Volumes[0].VolumeId'
)

function wait_for_volume_detachment() {
    until [ "$(aws ec2 describe-volumes --volume-ids "${1:-}" | jq -r '.Volumes[0].State')" = available ]; do
        echo "Waiting for volume ${1:-} to be detached..."
        sleep 1
    done
}

function wait_for_volume_attachment() {
    until [ "$(aws ec2 describe-volumes --volume-ids "${1:-}" | jq -r '.Volumes[0].Attachments[0].State')" = attached ]; do
        echo "Waiting for volume ${1:-} to be attached..."
        sleep 1
    done
}

function get_volume_device() {
    lsblk -rp -o name,serial | grep "${1#vol-}" | cut -d' ' -f1
}

if mount | grep -F -- "${MOUNT_PATH}"; then
    echo "${MOUNT_PATH} is already mounted with a device." >&2
    exit
fi

INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
VOLUME_ID="$(get_volume_id "${tags[@]}")"

if [[ -z "${VOLUME_ID}" || "${VOLUME_ID}" = null ]]; then
    die "A VOLUME_ID could not be determined with the given --volume-tags ${tags[*]:-}"
fi

aws ec2 attach-volume --instance-id "${INSTANCE_ID}" --device "${DEVICE_PATH}" --volume-id "${VOLUME_ID}"
wait_for_volume_attachment "${VOLUME_ID}"
echo 'Waiting for disk to become available.'
until [ -n "$(get_volume_device "${VOLUME_ID}")" ]; do
    echo "Retrying to detect volume device for volume ${VOLUME_ID}." >&2
    sleep 1
done
VOLUME_DEVICE="$(get_volume_device "${VOLUME_ID}")"

if [ ! "${VOLUME_DEVICE}" = "${DEVICE_PATH}" ]; then
  echo "WARNING: volume device '${VOLUME_DEVICE}' does not match requested device '${DEVICE_PATH}'." >&2
fi


if [ ! -e "${VOLUME_DEVICE:-}" ]; then
    echo "ERROR: ${VOLUME_ID} could not determine the attached volume device." >&2
    echo "See article: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html" >&2
    echo "Known mounted partitions:" >&2
    cat /proc/partitions
    echo "Known attached disks:" >&2
    lsblk -rp -o name,serial
    echo "Known amazon storage controllers:" >&2
    lspci -d 1d0f:8061
    echo "All known amazon PCI devices:" >&2
    lspci -d 1d0f:
    die "Unable to proceed because we don't know the device of the attached volume."
fi

REAL_DEVICE="$(readlink -f "${VOLUME_DEVICE}")"
REQUIRED_FORMAT=no
if ! blkid | grep -F -- "${REAL_DEVICE}:"; then
    REQUIRED_FORMAT=yes

    # agcount is for allocation groups for XFS parallel performance
    # in general it should be the count of the processors on the system.
    # For Jenkins scale, we expect around 4-16 CPU cores so I'm setting it to 8
    # as a happy medium.
    mkfs.xfs -K -d agcount=8 "${REAL_DEVICE}"
fi

mount "${VOLUME_DEVICE}" "${MOUNT_PATH}"

if [[ "${REQUIRED_FORMAT}" = yes && -n "${CHOWN_VALUE}" ]]; then
    chown -- "${CHOWN_VALUE}" "${MOUNT_PATH}"
fi

DEVICE_UUID="$(lsblk -no UUID "${VOLUME_DEVICE}")"
grep -F -- "${MOUNT_PATH}" /etc/fstab ||
    echo "UUID=${DEVICE_UUID} ${MOUNT_PATH} xfs noatime,nodiratime,nobarrier 0 0" |
    tee -a /etc/fstab
