; Make Flower script for use with The Gimp
; Creates a new image and generates a new flower in it

; This script is released into the public domain.
; You may redistribute and/or modify this script or extract segments without prior consent.

; This script is distributed in the hope of being useful
; but without warranty, explicit or otherwise.

;Define Script

(define (make-flower measure petalsize petalnum petalbump petaldir centrebump color1 color2 color3)

; Fix defined values if needed
(if (< measure 200)
(set! measure 200))
(if (> petalbump 65)
(set! petalbump 65))
(if (> centrebump 65)
(set! centrebump 65))

;Declare Variables

    (let* 
    (
	(theImage)
	(theActive)
	(base-layer)
	(flower-layer)
	(petal-layer)
	(petal2-layer)
	(petal3-layer)
	(petal4-layer)
	(petal5-layer)
	(petal6-layer)
	(shade-layer)
	(map-layer)

	(varX1)
	(varY1)
	(varX2)
    )

(gimp-context-push)

; Create New Image

(set! theImage (car (gimp-image-new measure measure 0)))

; Set a new layer

(set! base-layer (car (gimp-layer-new theImage measure measure 0 "Background" 100 0)))

; Disable Undo Group

(gimp-image-undo-disable theImage)

; Fill the layer with White

(gimp-context-set-background '(255 255 255))
(gimp-drawable-fill base-layer 1)

; Add the set layer

(gimp-image-add-layer theImage base-layer 0)

; Set a layer for the first petal

(set! flower-layer (car (gimp-layer-new theImage measure measure 1 "Flower" 100 0)))

; Fill and add the set layer

(gimp-drawable-fill flower-layer 3)
(gimp-image-add-layer theImage flower-layer -1)

; Define variables for petal creation based on user input for petal size

; Thin Petals

(if (= petalsize 2)
(begin
(set! varX1 (* (/ measure 10) 4))
(set! varY1 (* (/ measure 100) 6))
(set! varX2 (/ measure 10))
))

; Average Petals

(if (= petalsize 1)
(begin
(set! varX1 (* (/ measure 20) 7))
(set! varY1 (* (/ measure 100) 3))
(set! varX2 (* (/ measure 20) 3))
))

; Thick Petals

(if (= petalsize 0)
(begin
(set! varX1 (* (/ measure 10) 3))
(set! varY1 (/ measure 100))
(set! varX2 (* (/ measure 10) 2))
))

; Make a circle selection on the left side

(gimp-ellipse-select theImage varX1 varY1 (- (/ measure 2) 1) (- (/ measure 2) 1) 0 TRUE FALSE 0)

; Make a new circle selection on the opposite side that intersects

(gimp-ellipse-select theImage varX2 varY1 (- (/ measure 2) 1) (- (/ measure 2) 1) 3 TRUE FALSE 0)

; Set up petal colours

(gimp-context-set-foreground color1)
(gimp-edit-bucket-fill flower-layer 0 0 100 255 FALSE 0 0)
(gimp-selection-shrink theImage 1)
(gimp-context-set-background color2)
(gimp-edit-bucket-fill flower-layer 1 0 100 255 FALSE 0 0)
(gimp-selection-shrink theImage 5)
(gimp-edit-bucket-fill flower-layer 0 0 100 255 FALSE 0 0)
(gimp-selection-none theImage)

; Set up values for Cloud Layer X and Y

(if (= petaldir 0)
(begin
(set! varX1 8)
(set! varY1 4)
))

(if (= petaldir 1)
(begin
(set! varX1 4)
(set! varY1 8)
))

(if (= petaldir 2)
(begin
(set! varX1 8)
(set! varY1 8)
))

; New layer, fill with solid noise clouds, bump-map the flower layer and then remove the clouds layer.
; Only do this if Petal Ripple Intensity is not set to zero.

(if (> petalbump 0)
(begin
(set! petal-layer (car (gimp-layer-new theImage measure measure 1 "Clouds" 100 0)))
(gimp-drawable-fill petal-layer 3)
(gimp-image-add-layer theImage petal-layer -1)
(plug-in-solid-noise 1 theImage petal-layer 0 0 10 0 varX1 varY1)
(plug-in-bump-map 1 theImage flower-layer petal-layer 135 45 petalbump 0 0 0 0 1 0 0)
(gimp-image-remove-layer theImage petal-layer)
))

; Dup petals, rotate then merge all for 6 petals

(if (= petalnum 1)
(begin

; Duplicate layers and rotate by roughly 60 degrees each time

(gimp-image-set-active-layer theImage flower-layer)
(set! petal-layer (car (gimp-layer-copy flower-layer TRUE)))
(gimp-image-add-layer theImage petal-layer -1)
(gimp-drawable-transform-rotate petal-layer 1.05 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-set-active-layer theImage petal-layer)
(set! petal2-layer (car (gimp-layer-copy petal-layer TRUE)))
(gimp-image-add-layer theImage petal2-layer -1)
(gimp-drawable-transform-rotate petal2-layer 1.05 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-set-active-layer theImage petal2-layer)
(set! petal3-layer (car (gimp-layer-copy petal2-layer TRUE)))
(gimp-image-add-layer theImage petal3-layer -1)
(gimp-drawable-transform-rotate petal3-layer 1.05 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-set-active-layer theImage petal3-layer)
(set! petal4-layer (car (gimp-layer-copy petal3-layer TRUE)))
(gimp-image-add-layer theImage petal4-layer -1)
(gimp-drawable-transform-rotate petal4-layer 1.05 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-set-active-layer theImage petal4-layer)
(set! petal5-layer (car (gimp-layer-copy petal4-layer TRUE)))
(gimp-image-add-layer theImage petal5-layer -1)
(gimp-drawable-transform-rotate petal5-layer 1.05 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)

; Use alpha-to-selection to avoid the double overlap onto the first petal

(gimp-selection-layer-alpha flower-layer)
(gimp-edit-clear petal5-layer)
(gimp-edit-clear petal4-layer)
(gimp-selection-none theImage)

; Merge all together

(gimp-image-merge-down theImage petal5-layer 2)
(set! petal5-layer (car (gimp-image-get-active-layer theImage)))
(gimp-image-merge-down theImage petal5-layer 2)
(set! petal5-layer (car (gimp-image-get-active-layer theImage)))
(gimp-image-merge-down theImage petal5-layer 2)
(set! petal5-layer (car (gimp-image-get-active-layer theImage)))
(gimp-image-merge-down theImage petal5-layer 2)
(set! petal5-layer (car (gimp-image-get-active-layer theImage)))
(gimp-image-merge-down theImage petal5-layer 2)
(set! flower-layer (car (gimp-image-get-active-layer theImage)))
))

; Dup petal, rotate 180 and merge down

(gimp-image-set-active-layer theImage flower-layer)
(set! petal-layer (car (gimp-layer-copy flower-layer TRUE)))
(gimp-image-add-layer theImage petal-layer -1)
(gimp-drawable-transform-rotate flower-layer 3.14 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-merge-down theImage petal-layer 2)
(set! flower-layer (car (gimp-image-get-active-layer theImage)))

; Dup petal, rotate 90 and merge down for 4 petals

(if (= petalnum 0)
(begin
(gimp-image-set-active-layer theImage flower-layer)
(set! petal-layer (car (gimp-layer-copy flower-layer TRUE)))
(gimp-image-add-layer theImage petal-layer -1)
(gimp-drawable-transform-rotate flower-layer 1.57 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-merge-down theImage petal-layer 2)
(set! flower-layer (car (gimp-image-get-active-layer theImage)))
))

; Dup petal, rotate 90, dup again, rotate 45 and merge down for 4 petals

(if (= petalnum 2)
(begin
(gimp-image-set-active-layer theImage flower-layer)
(set! petal-layer (car (gimp-layer-copy flower-layer TRUE)))
(gimp-image-add-layer theImage petal-layer -1)
(gimp-drawable-transform-rotate flower-layer 1.57 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-merge-down theImage petal-layer 2)
(set! flower-layer (car (gimp-image-get-active-layer theImage)))

(gimp-image-set-active-layer theImage flower-layer)
(set! petal-layer (car (gimp-layer-copy flower-layer TRUE)))
(gimp-image-add-layer theImage petal-layer -1)
(gimp-drawable-transform-rotate flower-layer 0.76 FALSE (/ measure 2) (/ measure 2) 0 2 FALSE 3 1)
(gimp-image-merge-down theImage petal-layer 2)
(set! flower-layer (car (gimp-image-get-active-layer theImage)))
))

; Apply a shading layer to the petals

(set! shade-layer (car (gimp-layer-new theImage measure measure 1 "Shading" 100 5)))
(gimp-drawable-fill shade-layer 3)
(gimp-image-add-layer theImage shade-layer -1)
(gimp-selection-layer-alpha flower-layer)
(gimp-ellipse-select theImage (+ 6 (* (/ measure 10) 4)) (+ 6 (* (/ measure 10) 4)) (- (/ measure 5) 12) (- (/ measure 5) 12) 1 TRUE TRUE (/ measure 50))
(gimp-context-set-foreground '(0 0 0))
(gimp-context-set-background '(255 255 255))
;(gimp-context-set-gradient "FG to BG (RGB)")
(gimp-context-set-gradient "Default")
(gimp-edit-blend shade-layer 0 0 2 100 0 0 TRUE FALSE 1 0 TRUE (/ measure 2) (/ measure 2) measure measure)
(gimp-selection-none theImage)
(gimp-image-set-active-layer theImage flower-layer)
(set! petal-layer (car (gimp-layer-new theImage measure measure 1 "Centre" 100 0)))
(gimp-drawable-fill petal-layer 3)
(gimp-image-add-layer theImage petal-layer -1)
(gimp-image-set-active-layer theImage petal-layer)

; New layer, draw out a circle in the middle and solid fill

(gimp-ellipse-select theImage (* (/ measure 10) 4) (* (/ measure 10) 4) (/ measure 5) (/ measure 5) 0 TRUE FALSE 0)
(gimp-context-set-background color2)
(gimp-context-set-foreground color3)
(gimp-edit-bucket-fill petal-layer 1 0 100 255 FALSE 0 0)
(gimp-selection-shrink theImage 5)
(gimp-edit-bucket-fill petal-layer 0 0 100 255 FALSE 0 0)
(gimp-selection-feather theImage (/ measure 50))

; Add pattern for bump map purposes, then apply bump map. Remove bump map layer and merge remaining 2 layers.
; Only bumpmap if the Centre Bump setting was not at zero. Ignore if set to zero.

(set! map-layer (car (gimp-layer-new theImage measure measure 1 "Centre Shading" 70 21)))
(gimp-drawable-fill map-layer 3)
(gimp-image-add-layer theImage map-layer -1)
(if (> centrebump 0)
(begin
(gimp-context-set-pattern "Leather")
(gimp-edit-bucket-fill map-layer 2 0 100 255 FALSE 0 0)
(gimp-selection-none theImage)
(gimp-image-set-active-layer theImage petal-layer)
(plug-in-bump-map 1 theImage petal-layer map-layer 135 45 centrebump 0 0 0 0 1 0 0)
(gimp-selection-layer-alpha map-layer)
))
(gimp-context-set-foreground '(0 0 0))
(gimp-context-set-background '(255 255 255))
(gimp-edit-blend map-layer 0 0 2 100 0 0 TRUE FALSE 1 0 TRUE (/ measure 2) (/ measure 2) (- (/ measure 1.5) (/ measure 20)) (- (/ measure 1.5) (/ measure 20)))
(gimp-selection-none theImage)

; (gimp-image-remove-layer theImage map-layer)
; (gimp-image-set-active-layer theImage petal-layer)
; (gimp-image-merge-down theImage petal-layer 2)
; (set! flower-layer (car (gimp-image-get-active-layer theImage)))
(gimp-image-set-active-layer theImage flower-layer)

; Display the image

(gimp-display-new theImage)

; Enable Undo Group

(gimp-image-undo-enable theImage)

(gimp-context-pop)

)
)

; Register Script

(script-fu-register 	"make-flower"
			_"<Toolbox>/Xtns/Misc/Make Flower..."
			"Generates a flower in a new image"
			"Daniel Bates"
			"Daniel Bates"
			"Dec 2007"
			""
			SF-VALUE "                  (      200)" "500"
			SF-OPTION _"            " '(_"   " _"      " _"   ")
			SF-OPTION _"            " '(_"4" _"6" _"8")
			SF-VALUE "                  (0 to disable)" "30"
			SF-OPTION _"                  " '(_"      " _"      " _"      ")
			SF-VALUE "            (0 to disable)" "5"
			SF-COLOR "            " '(230 120 210)
			SF-COLOR "            " '(170 50 150)
			SF-COLOR "            " '(170 170 50)
)
				