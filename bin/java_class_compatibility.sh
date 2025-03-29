#!/bin/bash
# Created by Sam Gleske
# MIT License
# DESCRIPTION
#   Detect Java bytecode version from binary class file.  This script tells you
#   which version of Java the class is targeting (minimum version of Java).
#
#   You can analayze several classes against a desired minimum Java.  If any of
#   the classes are higher than the desired minimum Java, then they will be
#   surfaced to stdout.
set -euo pipefail

class_files=()
validate=false
compare_to_java=""

helpdoc() {
cat <<EOF
SYNOPSIS
  ${0##*/} [--validate] [--java JAVA] FILES...

DESCRIPTION
  Reads one or more Java class files and inspects the binary header to
  determine the minimum java version.  Optionally, you can inspect a list of
  class files and compare to a desired java version and print which class files
  do not match the desired Java version.

  With no extra options, simply tells you the minimum version of Java for which
  a binary class is compatible.

OPTIONS
  -j JAVA, --java JAVA
    Compare class files and print when a class file does not match the desired
    version of JAVA.
  -V, --validate
    Exit non-zero if any provided files do not match the expected Java version
    provided by --java option.
  -h, --help
    See this help document.

ARGUMENTS
  FILES...
    One ore more files expected to be Java class files

EXAMPLE
  Analyze a Jar and validate it is compatible with Java 8.  According to
  'man zip' DIAGNOSTICS section it is safe to ignore exit codes 1, 2, and 11.

      mkdir jar-folder
      cd jar-folder
      extract_file=../example.jar
      unzip -q -o "\$extract_file" '*.class' '*.jar' '*.ear' '*.war' '*.aar' '*.so' '*.dll' '*.dylib' || ! [ "\$?" -gt 2 -a ! "\$?" -eq 11 ]
      # extract child jars
      find . -type f \\( -name '*.jar' -o -name '*.ear' -o -name '*.war' \\) -print0 | \\
        xargs -x -0 -n1 -I{} \\
          /bin/bash -c \\
            'file="{}";dir="\${file##*/}"; [ ! -d "\$dir" ] || exit 0; set -x; mkdir "\$dir"; unzip -q -o "\$file" "*.class" "*.jar" "*.ear" "*.war" "*.aar" "*.so" "*.dll" "*.dylib" -d "\$dir" || ! [ "\$?" -gt 2 -a ! "\$?" -eq 11 ]'

      # validate java byte code of classes (in batches of up to -n50k)
      find . -type f -name '*.class' -print0 | xargs -0 -n50000 -- ${0##*/} --validate --java 8

      # find platform-dependent libraries
      find . -type f \\( -name '*.so' -o -name '*.dll' -o -name '*.dylib' \\)


  Analyze the binary of a Java class file without this handy script.
  hexdump options explained:
  * \`7/1 "%3x"\` read 1 byte and print it as hex (\`/1 "%3x"\`) and repeat 7 times (read first 7 bytes)
  * On the 8th byte, read 1 byte and print it as base10 decimal (\`/1 " %3d"\`)
  * Followed by reading no bytes, but add a newline at the end of the output (\`/0 "\\n"\`)
  * dd/hexdump example below will output "ca fe ba be  0  0  0  55"
    * "cafebabe" means the binary is a Java class.
    * "55" means the bytecode is targetting minimum Java 11.

      dd if=Main.class bs=8 count=1 status=none | hexdump -e '7/1 "%3x" /1 " %3d" /0 "\\n"'

SEE ALSO
  unzip(1)

  https://stackoverflow.com/questions/9170832/list-of-java-class-file-format-major-version-numbers
  https://docs.oracle.com/javase/specs/jvms/se23/html/jvms-4.html
AUTHORS
  Created by Sam Gleske.
EOF
  exit 1
}

process_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)
        helpdoc
        ;;
      -j|--java)
        compare_to_java="$(get_decimal_from_java_version "$2")"
        shift
        shift
        ;;
      -V|--validate)
        validate=true
        shift
        ;;
      *)
        class_files+=( "$1" )
        shift
        ;;
    esac
  done
}

get_decimal_from_java_version() {
  case "$1" in
    23) echo '67' ;;
    22) echo '66' ;;
    21) echo '65' ;;
    20) echo '64' ;;
    19) echo '63' ;;
    18) echo '62' ;;
    17) echo '61' ;;
    16) echo '60' ;;
    15) echo '59' ;;
    14) echo '58' ;;
    13) echo '57' ;;
    12) echo '56' ;;
    11) echo '55' ;;
    10) echo '54' ;;
    9) echo '53' ;;
    8|1.8) echo '52' ;;
    7|1.7) echo '51' ;;
    6|1.6) echo '50' ;;
    5|1.5) echo '49' ;;
    1.4) echo '48' ;;
    1.3) echo '47' ;;
    1.2) echo '46' ;;
    1.1|1.0.2) echo '45' ;;
    *)
      echo "Error: '$1' is an unknown java version." >&2
      exit 1
      ;;
  esac
}

# https://stackoverflow.com/questions/9170832/list-of-java-class-file-format-major-version-numbers
get_java_version_from_byte() {
  local decimal_num="$((0x$1))"
  case "$decimal_num" in
    67) echo '23' ;;
    66) echo '22' ;;
    65) echo '21' ;;
    64) echo '20' ;;
    63) echo '19' ;;
    62) echo '18' ;;
    61) echo '17' ;;
    60) echo '16' ;;
    59) echo '15' ;;
    58) echo '14' ;;
    57) echo '13' ;;
    56) echo '12' ;;
    55) echo '11' ;;
    54) echo '10' ;;
    53) echo '9' ;;
    52) echo '8' ;;
    51) echo '7' ;;
    50) echo '6' ;;
    49) echo '5' ;;
    48) echo '1.4' ;;
    47) echo '1.3' ;;
    46) echo '1.2' ;;
    45) echo '1.1 or 1.0.2' ;;
    *)
      echo "Error: '$1' byte is an unknown java version." >&2
      exit 1
      ;;
  esac
}

compare_java_to_minimum() {
  local found_java="$((0x$1))"
  local minimum_java="$((0x$2))"
  [ "$found_java" -le "$minimum_java" ]
}

get_first_8_bytes() {
  dd if="$1" bs=8 count=1 status=none | xxd -p | tr -d '\n'
}

minimum_compatible_java() {
  local java_decimal="$(echo "$@" | xargs -n1 | sort -nr | head -n1)"
  local java_byte="$(printf "%x" "$java_decimal")"
  get_java_version_from_byte "$java_byte"
}

append_found_javas() {
  if [ -z "${found_javas:-}" ]; then
    found_javas+=( "$1" )
    return
  fi
  for y in "${found_javas[@]}"; do
    if [ "$y" = "$1" ]; then
      return
    fi
  done
  found_javas+=( "$1" )
}

process_args "$@"

if [ "${#class_files[@]}" -lt 1 ]; then
  echo 'At least one class file must be provided.' >&2
  echo 'See also --help.' >&2
  exit 1
fi

if [ -n "${compare_to_java:-}" ]; then
  java_byte="$(printf "%x" "$compare_to_java")"
  echo "Comparing ${#class_files[@]} classes against Java $(get_java_version_from_byte "$java_byte")."
fi

found_javas=()
result=0
for x in "${class_files[@]}"; do
  if [ ! -f "$x" ]; then
    echo "WARNING: '$1' does not appear to be a Java class file" >&2
    result=1
    continue
  fi

  # read binary data to inspect for Java compatibility
  bytes="$(get_first_8_bytes "$x")"

  if ! grep '^cafebabe' <<< "$bytes" > /dev/null; then
    echo "WARNING: '$1' does not appear to be a Java class file" >&2
    result=1
    continue
  fi

  last_byte="$(echo -n "$bytes" | tail -c2)"
  append_found_javas "$((0x${last_byte}))"
  if [ -n "${compare_to_java-}" ]; then
    compare_to_desired_java_byte="$(printf "%x" "$compare_to_java")"
    if compare_java_to_minimum "$last_byte" "$compare_to_desired_java_byte"; then
      # Java compatibility would work with desired java
      continue
    else
      echo "Java $(get_java_version_from_byte "$last_byte"): '${x}'" >&2
      result=1
      continue
    fi
  fi

  echo "Java $(get_java_version_from_byte "$last_byte"): '${x}'" >&2
done

min_java="$(minimum_compatible_java "${found_javas[@]}")"
echo "Compatible with Java ${min_java} or higher." >&2

if [ "$validate" = true ]; then
  exit "$result"
else
  exit 0
fi
