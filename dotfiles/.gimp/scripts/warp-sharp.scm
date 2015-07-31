;;; warp-sharp.scm
;;; Date: <2006/07/13 15:06 simon@gimp.org>
;;; Author: Simon Budig <simon@gimp.org>
;;; Version 1.5

;;; Version 1.5 updated for Gimp 2.2 and later (changed menu registration)
;;; Version 1.4 updated for Gimp 1.3 and 2.0.

;;; This implements a method to sharpen images described by Joern Loviscach
;;; in the german computer magazine c't, 22/1999.

;;; Basically it "squeezes" unsharp edges. This method is a simplified
;;; Version of an algorithm by Nur Arad and Craig Gotsman:
;;; "Enhancement by Image-Dependent Warping", IEEE Transactions on
;;; Image Processing, 1999, Vol. 8, No. 8, S. 1063

(define (script-fu-warp-sharp img drw edge-strength blur-strength bump-depth displace-amount)
  (let* ((drawable-width (car (gimp-drawable-width drw)))
	 (drawable-height (car (gimp-drawable-height drw)))
	 (drawable-type (car (gimp-drawable-type drw)))
         (old-selection 0)
	 ; layer for detecting edges
         (edge-layer (car (gimp-layer-copy drw 0)))
	 ; layer for x-displace information
         (x-displace-layer (car (gimp-layer-new img drawable-width
                          drawable-height drawable-type "Displace X" 100 0)))
	 ; layer for x-displace information
         (y-displace-layer (car (gimp-layer-new img drawable-width
                          drawable-height drawable-type "Displace Y" 100 0)))
         (selection-info (gimp-selection-bounds img))
         (has-selection (car selection-info))
         (bump-xoff 0)
         (bump-yoff 0)
        )
    (gimp-image-undo-group-start img)
    (if has-selection (begin
        ; If there is a selection don't render too much.
        (set! old-selection
                (car (gimp-channel-copy (car (gimp-image-get-selection img)))))
        (gimp-selection-grow img (+ blur-strength bump-depth displace-amount))
        (set! selection-info (gimp-selection-bounds img))
        (set! bump-xoff (cadr selection-info))
        (set! bump-yoff (caddr selection-info))
    ))
    ; set up the layers
    (gimp-drawable-fill x-displace-layer 2)
    (gimp-drawable-fill y-displace-layer 2)
    (gimp-image-add-layer img edge-layer -1)
    (gimp-image-add-layer img y-displace-layer -1)
    (gimp-image-add-layer img x-displace-layer -1)

    ; detect the edges and blur the layer a little bit
    (plug-in-edge 1 img edge-layer edge-strength 1 0)
    (if (>= blur-strength 1)
        (plug-in-gauss-iir 1 img edge-layer blur-strength 1 1))

    ; create the displacement-maps by bump-mapping the edges.
    ; elevation=30: areas without edges will get a 50 % gray.
    (plug-in-bump-map 1 img x-displace-layer edge-layer 0 30
                      bump-depth bump-xoff bump-yoff 0 0 0 0 0)
    (plug-in-bump-map 1 img y-displace-layer edge-layer 270 30
                      bump-depth bump-xoff bump-yoff 0 0 0 0 0)
    ; restore the old selection
    (if has-selection (begin
        (gimp-selection-load old-selection)
        (gimp-drawable-delete old-selection)
    ))
    ; finally displace the image.
    (plug-in-displace 1 img drw displace-amount displace-amount 1 1
                      x-displace-layer y-displace-layer 1)

    ; clean up...
    (gimp-image-remove-layer img edge-layer)
    (gimp-image-remove-layer img x-displace-layer)
    (gimp-image-remove-layer img y-displace-layer)
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)))

(script-fu-register
    "script-fu-warp-sharp"
    "_Warp sharp"
    "Sharpen the current drawable by squeezing unsharp edges. Algorithm described by Joern Loviscach in c't 22/1999, p 236."
    "Simon Budig <simon@gimp.org>"
    "Simon Budig"
    "13. 06. 2006"
    "RGB RGBA GRAY GRAYA"
    SF-IMAGE "Image" 0
    SF-DRAWABLE "Drawable" 0
    SF-ADJUSTMENT "Edge detection" '(7 1 10 0.1 1 1 0)
    SF-ADJUSTMENT "Blur radius" '(3 0 10 0.1 1 1 0)
    SF-ADJUSTMENT "Bump depth" '(2 1 10 1 1 0 0)
    SF-ADJUSTMENT "Displace intensity" '(2.5 0.1 10 0.1 0.5 1 0)
)

; new in 2.2, for older versions give the full menu path in the
; second parameter of the script-fu-register call.
(script-fu-menu-register "script-fu-warp-sharp"
    "<Image>/Filters/Enhance")
