; Ambigram Rotation script for use with The Gimp
; Copies and rotates layers set up for an animation

; This script is released into the public domain.
; You may redistribute and/or modify this script or extract segments without prior consent.

; This script is distributed in the hope of being useful
; but without warranty, explicit or otherwise.

;Define Script

(define (userscript-ambigram-rotation-ip theImage theDraw theRotation theDelay)

;Declare Variables

    (let* 
    (
	(theLayer)
	(theBG)
	(theNewLayer)
	(theNewBG)
	(theActive)
	(theNumber)
	(theAngle 10)
	(theFrame 2)
    )

; Check number of layers. If less than 2, abort script

(if (< (car (gimp-image-get-layers theImage)) 2)
(begin
(set! theLayer (car (gimp-message-get-handler)))
(gimp-message-set-handler 0)
(gimp-message "Error: This script requires a minimum of 2 layers!")
(gimp-message-set-handler theLayer))
(begin

; Begin Undo Group

(gimp-undo-push-group-start theImage)

; Set temporary context area (to maintain previous user options for when script terminates)

(gimp-context-push)

; Adjust delay for ease of use in setting frame delay

(set! theDelay (* theDelay 1000))

; Set the respective layers to variables

(set! theLayer (aref (cadr (gimp-image-get-layers theImage)) (- (car (gimp-image-get-layers theImage)) 2)))
(set! theBG (aref (cadr (gimp-image-get-layers theImage)) (- (car (gimp-image-get-layers theImage)) 1)))
(set! theActive (aref (cadr (gimp-image-get-layers theImage)) (- (car (gimp-image-get-layers theImage)) 2)))
(set! theActive (gimp-image-set-active-layer theImage theActive))

; Set the number of repetitions based on user input

(if (= theRotation FALSE)
(set! theNumber 17)
(set! theNumber 35))

; Create while loop for layers

(while (> theNumber 0)

; Assign layer duplicates to variables

(set! theNewLayer (car (gimp-layer-copy theLayer TRUE)))
(set! theNewBG (car (gimp-layer-copy theBG TRUE)))

; Add BG and object layers to image

(gimp-image-add-layer theImage theNewBG -1)
(gimp-image-add-layer theImage theNewLayer -1)

; Perform a rotate on object layer

(gimp-drawable-transform-rotate theNewLayer (* theAngle (/ 3.14 180)) TRUE (car (gimp-drawable-width theNewLayer)) (car (gimp-drawable-width theNewLayer)) 1 2 FALSE 1 0)

; Increment angle for next runthrough
(set! theAngle (+ theAngle 10))

; Merge layers

(gimp-image-merge-down theImage theNewLayer 0)
(set! theActive (car (gimp-image-get-active-layer theImage)))

; Rename layer to add timing and disposal

(gimp-drawable-set-name theActive (string-append "Frame#" (number->string theFrame) " (30ms) (replace)"))
(set! theFrame (+ theFrame 1))

(set! theNumber (- theNumber 1))

)

; Merge first 2 layers

(gimp-image-merge-down theImage theLayer 0)
(set! theActive (car (gimp-image-get-active-layer theImage)))

; Add timing value to first layer

(gimp-drawable-set-name theActive (string-append "Frame#1" " (" (number->string theDelay) "ms)"))

; Add timing value to 18th layer if 360 was requested

(if (= theRotation TRUE)
(begin
(set! theNewLayer (aref (cadr (gimp-image-get-layers theImage)) (- (car (gimp-image-get-layers theImage)) 19)))
(gimp-drawable-set-name theNewLayer (string-append "Frame#19" " (" (number->string theDelay) "ms) (replace)"))
))

; Update display

(gimp-displays-flush)

; Ditch temporary context area

(gimp-context-pop)

; End Undo Group

(gimp-undo-push-group-end theImage)

))
)
)

; Register Script

(script-fu-register 	"userscript-ambigram-rotation-ip"
			"<Image>/Filters/Animation/Ambigram Rotation..."
			"Copies and rotates layers set up for an animation"
			"Daniel Bates"
			"Daniel Bates"
			"Jan 2008"
              		"*"
			SF-IMAGE      "SF-IMAGE" 0
			SF-DRAWABLE   "SF-DRAWABLE" 0
			SF-TOGGLE "360?" FALSE
			SF-ADJUSTMENT "Delay (seconds)" '(15 0.1 120 0.1 1 1 1)
)
				
