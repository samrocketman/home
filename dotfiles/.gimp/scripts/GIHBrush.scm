; Script to aid in the creation of animated brushes that rotate as the brush moves.

; Rob Antonishen

(define (script-fu-setup-brush img inLayer inCount inNumber inColour)
; Image Height should equal Image Width  times inNumber
  (let* 
    (
      (pi 3.141592654)
       (img (car (gimp-image-duplicate img)))  ;create a duplicate
       (width (car (gimp-image-width img)))
       (height (car (gimp-image-height img)))
       ;(side (if (> width height) width height))
       (side width)
       (srcLayer 0)
       (floatSel 0)
       (counter 1)
       (counter2 0)
       (aRad 0)
     )
     
     ; it begins here
     (gimp-image-undo-group-start img)
     ; get active layer in new image
     (set! inLayer (aref (cadr (gimp-image-get-layers img)) 0))
     ; set the colour mode based on the checkbox
     (if (and (= inColour TRUE) (= (car (gimp-drawable-is-gray inLayer)) TRUE))
       (gimp-image-convert-rgb img) 0
     )
     (if (and (= inColour FALSE) (= (car (gimp-drawable-is-rgb inLayer)) TRUE))
       (gimp-image-convert-grayscale img) 0
     )
     ; enlarge to largest side and for ratated shapes
     ;(if (>= width height)
      (gimp-image-resize img (* side inCount) height 0 0)
    ;  (gimp-image-resize img (* side inCount) side (/ (- side width) 2) 0)
    ;)
     (gimp-layer-resize-to-image-size inLayer)
    (set! srcLayer (car (gimp-image-merge-visible-layers img 1)))
     
     ;add alpha if none
     (gimp-layer-add-alpha srcLayer) 
     ;erase outside the to be rotated selection
    ;(gimp-ellipse-select img 0 0 side side CHANNEL-OP-REPLACE TRUE FALSE 0)
     ;(gimp-selection-invert img)
    ; not working.....
     ;(gimp-edit-clear inLayer)     
     
     (while (< counter2 inNumber)
       (while (< counter inCount)
        ; get circular selection
        (gimp-ellipse-select img 0 (* counter2 side) side side CHANNEL-OP-REPLACE TRUE FALSE 0)
         ; copy
        (gimp-edit-copy srcLayer)
        ; paste as floating
         (set! floatSel (car (gimp-edit-paste srcLayer FALSE)))
          (set! aRad (* (/ (* pi 2) inCount) counter))
        ; rotate and move the floating layer
        (gimp-drawable-transform-2d floatSel (/ side 2) (+ (* counter2 side) (/ side 2)) 1 1 aRad 
                                     (+ (* side counter) (/ side 2)) (+ (* counter2 side) (/ side 2)) 
                                             TRANSFORM-FORWARD INTERPOLATION-CUBIC TRUE 3 TRANSFORM-RESIZE-ADJUST)
        ; anchor down
        (gimp-floating-sel-anchor floatSel)
         (set! counter (+ counter 1))
       )
       (set! counter 1)
       (set! counter2 (+ counter2 1))  
     )
     (gimp-image-undo-group-end img)
     (gimp-display-new img)
  )
)

(script-fu-register "script-fu-setup-brush"
                      "<Image>/Script-Fu/Utils/GIH Brush..."
                    "Set-up an animated brush that rotates."
                    "Rob Antonishen"
                    "Rob Antonishen"
                    "2004"
                    ""
                    SF-IMAGE      "image"      0
                    SF-DRAWABLE   "drawable"   0
                    SF-ADJUSTMENT "How many images to create?" '(12 2 36 1 2 0 1)
                    SF-ADJUSTMENT "How many source images?" '(1 1 6 1 2 0 1)
                    SF-TOGGLE     "Make it a Colour Brush (needs transparent background)?" FALSE
)                    
