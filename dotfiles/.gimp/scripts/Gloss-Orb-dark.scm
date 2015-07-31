;Author: Mike Pippin
;Version: 1.0
;Homepage: Split-visionz.net
;License: Released under the GPL included in the file with the scripts.

(define (script-fu-sv-gloss-orb-dark myradius bgcolor)

(let* (
	(buffer (* myradius 0.2))
	(image (car (gimp-image-new (+ buffer myradius) (+ buffer myradius) RGB)))
	(shadow-layer (car (gimp-layer-new image myradius myradius RGBA-IMAGE "shadowLayer" 100 NORMAL-MODE)))
	(grad-layer (car (gimp-layer-new image myradius myradius RGBA-IMAGE "gradLayer" 100 NORMAL-MODE)))
	(dark-layer (car (gimp-layer-new image myradius myradius RGBA-IMAGE "darkLayer" 100 NORMAL-MODE)))	
	(hl-layer (car (gimp-layer-new image myradius myradius RGBA-IMAGE "hlLayer" 100 NORMAL-MODE)))
	(shrink-size (* myradius 0.01))
	(hl-width (* myradius 0.7))
	(hl-height (* myradius 0.6))
	(offset (- myradius hl-width))
	(hl-x (/ offset 2));(/ (- myradius hl-width 2)))
	(hl-y 0)
	(quarterheight (/ myradius 4))
	(blur-radius (* myradius 0.1))

);end variable defines

(gimp-image-add-layer image shadow-layer 0)
(gimp-edit-clear shadow-layer)

(gimp-image-add-layer image grad-layer 0)
(gimp-edit-clear grad-layer)

(gimp-image-add-layer image dark-layer 0)
(gimp-edit-clear dark-layer)

(gimp-image-add-layer image hl-layer 0)
(gimp-edit-clear hl-layer)


;//////////////////////////////////////
;shadow layer
(gimp-ellipse-select image 0 0 myradius myradius 0 TRUE FALSE 0)
(gimp-context-set-foreground '(0 0 0))
(gimp-context-set-background '(0 0 0))
(gimp-edit-bucket-fill shadow-layer 0 0 100 0 FALSE 0 0)

;//////////////////////////////////////
;gradient layer
(gimp-context-set-background bgcolor)
(gimp-image-set-active-layer image grad-layer)
(gimp-edit-blend grad-layer 0  0 0 100 0 0 FALSE FALSE 0 0 TRUE 0 (- 1(/ myradius 2)) 0 myradius)

;//////////////////////////////////////
; highlight layer
(gimp-image-set-active-layer image hl-layer)
(gimp-context-set-foreground '(255 255 255))
(gimp-edit-blend hl-layer 2  0 0 100 0 0 FALSE FALSE 0 0 TRUE 0 0 0 myradius )

;//////////////////////////////
;dark layer
(gimp-image-set-active-layer image dark-layer)
(gimp-context-set-foreground '(0 0 0))
(gimp-context-set-background '(0 0 0))
(gimp-edit-bucket-fill dark-layer 0 0 100 0 FALSE 0 0)
(gimp-selection-shrink image shrink-size)
(gimp-selection-feather image (/ myradius 2))
(gimp-edit-cut dark-layer)



;Shrink highlight layer and move to proper position
(gimp-image-set-active-layer image hl-layer)
(gimp-layer-scale hl-layer hl-width hl-height FALSE)
(gimp-layer-translate hl-layer hl-x hl-y)
(gimp-layer-set-opacity hl-layer 75)
(gimp-layer-resize-to-image-size hl-layer)

;Move and blur shadow layer
(gimp-image-set-active-layer image shadow-layer)
(gimp-layer-translate shadow-layer (/ hl-x 4) (/ hl-x 4))
(gimp-layer-resize-to-image-size shadow-layer)
(plug-in-gauss-rle 1 image shadow-layer blur-radius 1 1)



(gimp-display-new image)
(gimp-displays-flush)
(gimp-image-clean-all image)

); end let scope

); end function define


(script-fu-register "script-fu-sv-gloss-orb-dark"
		    _"<Toolbox>/Xtns/SV-Scripts/Gloss-Orb-Dark"
		    "Creates a Web2.0 style gloss orb"
		    "Mike Pippin"
		    "copyright 2007-8, Mike Pippin"
		    "Dec 2007"
		    ""
		    SF-ADJUSTMENT _"Orb Radius" '(100 1 2000 1 10 0 1)
		    
			SF-COLOR      "Background Color" '(22 22 125)			
			)
			

