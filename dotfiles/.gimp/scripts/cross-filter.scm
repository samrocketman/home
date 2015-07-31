; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
; -----------------------------------------------------------------------
; The GIMP script-fu  Cross Filter.scm  for GIMP2.2
; Copyright (C) 2006  Tamagoro <tamagoro_1@yahoo.co.jp>
; ************************************************************************

(define (script-fu-cross-filter image drawable size number depth bright opacity color density threshold merge)

(let* ( (W (car (gimp-drawable-width drawable)))
        (H (car (gimp-drawable-height drawable)))
        (img (car (gimp-image-new W H 0)))
        (bg-layer (car (gimp-layer-new img W H 1 "Background" 100 NORMAL)))
        (grow-layer1 (car (gimp-layer-new img W H 1 "Grow Overlay" 100 OVERLAY-MODE)))
        (grow-layer2 (car (gimp-layer-new img W H 1 "Grow Screen" 100 SCREEN-MODE)))
        (selection? (car (gimp-selection-is-empty image)))
        (offx (car (gimp-drawable-offsets drawable)))
        (offy (cadr (gimp-drawable-offsets drawable)))
        (old-fg (car (gimp-context-get-foreground)))
        (old-bg (car (gimp-context-get-background)))
		(old-selection)
		(selection)
		(sparkle-layer1)
		(selection2)
		(copy-layer0)
		(copy-layer1)
		(copy-layer2)
		(highlight-selection)
		(sparkle-layer2)
		(sparkle-selection1)
		(sparkle-channel1)
		(sparkle-selection2)
		(sparkle-channel2)
		(angle)
		(sparkle-1)
		(sparkle-2)
		(sparkle)
		(old-gradient)
		(cross-layer)
		(new-layer1)
		(new-layer2)
		(new-layer3)
	)

  (gimp-undo-push-group-start image)
  (gimp-image-undo-disable img)
  (gimp-context-set-default-colors)

; -------------------------------------------------------------------------------
  (if (= selection? FALSE)
      (begin 
       (set! old-selection (car (gimp-selection-save image)))
       (gimp-rect-select image offx offy W H 2 FALSE 0)
       (gimp-edit-copy old-selection)
       (set! selection (car (gimp-channel-new img W H "selection" 0 '(0 0 0))))
       (gimp-image-add-channel img selection 0)
       (gimp-floating-sel-anchor (car (gimp-edit-paste selection FALSE)))
       (gimp-selection-none image) ))

  (gimp-edit-copy drawable)
  (gimp-image-add-layer img bg-layer 0)
  (gimp-edit-fill bg-layer TRANSPARENT-FILL)
  (gimp-floating-sel-anchor (car (gimp-edit-paste bg-layer FALSE)))
  (set! sparkle-layer1 (car (gimp-layer-copy bg-layer TRUE)))
  (gimp-image-add-layer img sparkle-layer1 -1)
  (if (= selection? TRUE)
      (gimp-levels-auto sparkle-layer1)
      (begin 
       (gimp-selection-load selection)
       (gimp-levels-auto sparkle-layer1)
       (gimp-selection-shrink img (/ size 2))
       (gimp-selection-invert img)
       (set! selection2 (car (gimp-selection-save img)))
       (gimp-selection-none img) ))
  (gimp-brightness-contrast sparkle-layer1 0 25)

; Make Highlight-selection ------------------------------------------------------
  (if (> threshold 0)
      (begin 
       (set! copy-layer0 (car (gimp-layer-copy sparkle-layer1 TRUE)))
       (set! copy-layer1 (car (gimp-layer-copy sparkle-layer1 TRUE)))
       (set! copy-layer2 (car (gimp-layer-copy sparkle-layer1 TRUE)))
       (gimp-threshold sparkle-layer1 threshold 255)
       (gimp-image-add-layer img copy-layer0 -1)
       (plug-in-edge 1 img copy-layer0 (- 10 (* threshold 0.035)) 1 0)
       (gimp-threshold copy-layer0 threshold 255)
       (gimp-layer-set-mode copy-layer0 DARKEN-ONLY)
       (set! sparkle-layer1 (car (gimp-image-merge-down img copy-layer0 0)))
       (gimp-by-color-select sparkle-layer1 '(0 0 0) 0 2 FALSE 0 1 FALSE)
       (set! highlight-selection (car (gimp-selection-save img)))
       (gimp-selection-none img) ))

; Make Sparkle-point ------------------------------------------------------------
  (gimp-edit-fill sparkle-layer1 FOREGROUND-FILL)
  ;(plug-in-scatter-rgb 1 img sparkle-layer1 FALSE FALSE 0.20 0.20 0.20 0.00)
  (plug-in-rgb-noise 1 img sparkle-layer1 FALSE FALSE 0.20 0.20 0.20 0.00)
  (set! sparkle-layer2 (car (gimp-layer-copy sparkle-layer1 TRUE)))
  (if (> threshold 0)
      (begin 
       (gimp-image-add-layer img copy-layer1 -1)
       (gimp-layer-set-mode copy-layer1 16)
       (gimp-layer-set-opacity copy-layer1 (+ 5 (* threshold 0.02)))
       (set! sparkle-layer1 (car (gimp-image-merge-down img copy-layer1 0)))
       (gimp-selection-load highlight-selection)
       (gimp-edit-fill sparkle-layer1 FOREGROUND-FILL)
       (gimp-selection-none img) ))

  (gimp-image-add-layer img sparkle-layer2 -1)
  (gimp-drawable-transform-rotate-simple sparkle-layer2 1 TRUE 0 0 FALSE)
  (if (> threshold 0)
      (begin 
       (gimp-image-add-layer img copy-layer2 -1)
       (gimp-layer-set-mode copy-layer2 16)
       (gimp-layer-set-opacity copy-layer2 (+ 5 (* threshold 0.02)))
       (set! sparkle-layer2 (car (gimp-image-merge-down img copy-layer2 0)))
       (gimp-selection-load highlight-selection)
       (gimp-edit-fill sparkle-layer2 FOREGROUND-FILL)
       (gimp-selection-none img) ))

  (if (= selection? FALSE)
      (begin 
       (gimp-selection-load selection2)
       (gimp-edit-fill sparkle-layer1 FOREGROUND-FILL)
       (gimp-edit-fill sparkle-layer2 FOREGROUND-FILL)
       (gimp-selection-none img) ))
  (gimp-threshold sparkle-layer1 (- 105 (* density 2)) 255)
  (gimp-threshold sparkle-layer2 (- 105 (* density 2)) 255)

; Save Selection ----------------------------------------------------------------
  (gimp-by-color-select sparkle-layer1 '(255 255 255) 0 2 FALSE 0 1 FALSE)
  (set! sparkle-selection1 (car (gimp-selection-is-empty img)))
  (set! sparkle-channel1 (car (gimp-selection-save img)))
  (gimp-by-color-select sparkle-layer2 '(255 255 255) 0 2 FALSE 0 1 FALSE)
  (set! sparkle-selection2 (car (gimp-selection-is-empty img)))
  (set! sparkle-channel2 (car (gimp-selection-save img)))
  (gimp-selection-none img)

; Make Sparkle ------------------------------------------------------------------
  (cond ((= number  4) (set! angle 135))
        ((= number  6) (set! angle   0))
        ((= number  8) (set! angle  45))
        ((= number 10) (set! angle  72))
        ((= number 12) (set! angle  60))
        ((= number 14) (set! angle  64))
        ((= number 16) (set! angle  45)))

  (if (= sparkle-selection1 FALSE)
      (begin 
       (plug-in-sparkle 1 img sparkle-layer1 0 0.50 size (/ number 2) angle 1.00 0 0 0 FALSE FALSE FALSE 0)
       (gimp-selection-load sparkle-channel1)
       (gimp-selection-grow img (/ size 4))
       (gimp-selection-feather img (* (/ size 4) 1.8))
       (gimp-bucket-fill sparkle-layer1 BG-BUCKET-FILL NORMAL (+ 70 (* bright 2)) 0 FALSE 0 0)
       (gimp-selection-none img) ))

  (if (= sparkle-selection2 FALSE)
      (begin 
       (plug-in-sparkle 1 img sparkle-layer2 0 0.50 (/ size 2) (/ number 2) angle 1.00 0 0 0 FALSE FALSE FALSE 0)
       (gimp-selection-load sparkle-channel2)
       (gimp-selection-grow img (/ (/ size 2) 4))
       (gimp-selection-feather img (* (/ (/ size 2) 4) 1.8))
       (gimp-bucket-fill sparkle-layer2 BG-BUCKET-FILL NORMAL (+ 70 (* bright 2)) 0 FALSE 0 0)
       (gimp-selection-none img) ))

  (gimp-layer-set-mode sparkle-layer2 LIGHTEN-ONLY)
  (set! sparkle-1 (car (gimp-image-merge-down img sparkle-layer2 0)))
  (cond ((= depth 1)( ))
        ((= depth 2)(plug-in-vpropagate 1 image sparkle-1 0 255 0.90 3 0 255))
        ((= depth 3)(plug-in-vpropagate 1 image sparkle-1 0 255 0.90 15 0 255)) )
  (gimp-brightness-contrast sparkle-1 0 25)
  (set! sparkle-2 (car (gimp-layer-copy sparkle-1 TRUE)))
  (gimp-image-add-layer img sparkle-2 -1)
  (gimp-layer-set-mode sparkle-2 SCREEN)
  (gimp-layer-set-opacity sparkle-2 80)
  (gimp-levels sparkle-1 0 128 255 1.0 0 255)
  (set! sparkle (car (gimp-image-merge-down img sparkle-2 0)))
  (gimp-layer-set-mode sparkle SCREEN)

; Make Grow-layer ---------------------------------------------------------------
  (gimp-image-add-layer img grow-layer1 -1)
  (gimp-image-add-layer img grow-layer2 -1)
  (gimp-edit-fill grow-layer1 TRANSPARENT-FILL)
  (gimp-edit-fill grow-layer2 FOREGROUND-FILL)
  (gimp-layer-set-opacity grow-layer1 (+ 80 (* bright 2)))
  (gimp-layer-set-opacity grow-layer2 (* bright 10))

  (if (= sparkle-selection1 FALSE)
      (begin 
       (gimp-selection-load sparkle-channel1)
       (gimp-selection-grow img (/ size 1.5))
       (gimp-selection-feather img (* (/ size 1.5) 2))
       (gimp-edit-fill grow-layer1 WHITE-FILL)
       (gimp-bucket-fill grow-layer2 BG-BUCKET-FILL NORMAL 50 0 FALSE 0 0)
       (gimp-selection-none img) ))

  (if (= sparkle-selection2 FALSE)
      (begin 
       (gimp-selection-load sparkle-channel2)
       (gimp-selection-grow img (/ (/ size 2) 1.5))
       (gimp-selection-feather img (* (/ (/ size 2) 1.5) 2))
       (gimp-edit-fill grow-layer1 WHITE-FILL)
       (gimp-bucket-fill grow-layer2 BG-BUCKET-FILL NORMAL 50 0 FALSE 0 0)
       (gimp-selection-none img) ))

; Colorize ---------------------------------------------------------------------
  (if (= color 0)
      (begin 
       (set! old-gradient (car (gimp-context-get-gradient)))
       (gimp-context-set-gradient "Full saturation spectrum CCW")
       (gimp-blend sparkle 3 OVERLAY 9 (* opacity 10) 0 0 FALSE FALSE 0 0 FALSE (/ W 2) (/ H 2) (/ W 2) (+ (/ H 2) size))
       (gimp-context-set-gradient old-gradient))
      (begin 
        (if (< 1 color)
         (begin 
          (cond 
           ((= color 2)(gimp-context-set-foreground '(0 0 255)))     ;Blue
           ((= color 3)(gimp-context-set-foreground '(0 255 0)))     ;Green
           ((= color 4)(gimp-context-set-foreground '(255 0 0)))     ;Red
           ((= color 5)(gimp-context-set-foreground '(0 255 255)))   ;Cyan
           ((= color 6)(gimp-context-set-foreground '(255 255 0)))   ;Yellow
           ((= color 7)(gimp-context-set-foreground '(255 0 255))) ) ;Magenta
          (gimp-selection-all img)
          (gimp-bucket-fill sparkle FG-BUCKET-FILL OVERLAY (* opacity 10) 255 FALSE 0 0)
          (gimp-bucket-fill grow-layer2 FG-BUCKET-FILL OVERLAY (* opacity 10) 255 FALSE 0 0)
          (gimp-selection-none img)))) )

; Clean up ---------------------------------------------------------------------
  (if (= merge FALSE)
      (begin 
       (gimp-floating-sel-anchor (car (gimp-edit-paste bg-layer FALSE)))
       (set! cross-layer (car (gimp-image-merge-visible-layers img 0)))
       (gimp-edit-copy cross-layer)
       (gimp-floating-sel-anchor (car (gimp-edit-paste drawable FALSE))) )
      (begin 
       (set! new-layer1 (car (gimp-layer-new image W H 1 "Sparkle" 100 SCREEN-MODE)))
       (set! new-layer2 (car (gimp-layer-new image W H 1 "Grow Overlay" 100 OVERLAY-MODE)))
       (set! new-layer3 (car (gimp-layer-new image W H 1 "Grow Screen" 50 SCREEN-MODE)))
       (gimp-drawable-fill new-layer1 TRANSPARENT-FILL)
       (gimp-drawable-fill new-layer2 TRANSPARENT-FILL)
       (gimp-drawable-fill new-layer3 TRANSPARENT-FILL)
       (gimp-image-add-layer image new-layer1 -1)
       (gimp-layer-set-offsets new-layer1 offx offy)
       (gimp-edit-copy sparkle)
       (gimp-floating-sel-anchor (car (gimp-edit-paste new-layer1 FALSE)))
       (gimp-image-add-layer image new-layer2 -1)
       (gimp-layer-set-opacity new-layer2 (+ 80 (* bright 2)))
       (gimp-layer-set-offsets new-layer2 offx offy)
       (gimp-edit-copy grow-layer1)
       (gimp-floating-sel-anchor (car (gimp-edit-paste new-layer2 FALSE)))
       (gimp-image-add-layer image new-layer3 -1)
       (gimp-layer-set-opacity new-layer3 (* bright 10))
       (gimp-layer-set-offsets new-layer3 offx offy)
       (gimp-edit-copy grow-layer2)
       (gimp-floating-sel-anchor (car (gimp-edit-paste new-layer3 FALSE))) ))

  (if (= selection? FALSE)
      (begin 
       (gimp-selection-load old-selection)
       (gimp-image-remove-channel image old-selection) ))

  (gimp-context-set-foreground old-fg)
  (gimp-context-set-background old-bg)
  (gimp-image-undo-enable img)
  (gimp-undo-push-group-end image)
  (gimp-image-delete img)
  (gimp-displays-flush)
))

;;Register ---------------------------------------------------------------------
;(script-fu-register "script-fu-cross-filter"
; 	"Cross Filter..."
; 	"Cross Filter"
; 	"Tamagoro <tamagoro_1@yahoo.co.jp>"
; 	"Tamagoro"
; 	"2006/06"
; 	"RGB*"
; 	SF-IMAGE      "Image"    0
; 	SF-DRAWABLE   "Drawable" 0 
; 	SF-ADJUSTMENT "Sparkle Radius (pixels)"   '(40 10 100 1 10 0 0)
; 	SF-ADJUSTMENT "Spike Number (4-16)"       '(8 4 16 2 2 0 1)
; 	SF-ADJUSTMENT "Spike Depth (1-3)"         '(1 1 3 1 1 0 1)
; 	SF-ADJUSTMENT "Sparkle brightness (1-10)" '(5 1 10 1 1 0 1)
; 	SF-ADJUSTMENT "Color Opacity (1-10)"      '(8 1 10 1 1 0 1)
; 	SF-OPTION     "Sparkle Color"             '("Rainbow Color" "White" "Blue" "Green" "Red" "Cyan" "Yellow" "Magenta")
; 	SF-ADJUSTMENT "Sparkle Density (1-10)"    '(5 1 10 1 1 0 0)
; 	SF-ADJUSTMENT "Threshold (0=Random)"      '(200 0 250 1 10 0 0)
;  	SF-TOGGLE     "Non Merge"                  FALSE  )

;;Register (Japanese Language)--------------------------------------------------
(script-fu-register "script-fu-cross-filter"
 	"Cross Filter..."
	""
 	"          <tamagoro_1@yahoo.co.jp>"
 	"Tamagoro"
 	"2006/06"
 	"RGB*"
 	SF-IMAGE      "Image"    0
 	SF-DRAWABLE   "Drawable" 0 
 	SF-ADJUSTMENT "                (      )"     '(40 10 100 1 10 0 0)
 	SF-ADJUSTMENT "             (4-16)"       '(8 4 16 2 2 0 1)
 	SF-ADJUSTMENT "                (1-3)"      '(1 1 3 1 1 0 1)
 	SF-ADJUSTMENT "             (1-10)"       '(5 1 10 1 1 0 1)
 	SF-ADJUSTMENT "             (1-10)"       '(8 1 10 1 1 0 1)
 	SF-OPTION     "         "                '("      " "   " "   " "   " "   " "         " "            " "            ")
 	SF-ADJUSTMENT "             (   -   )"      '(5 1 10 1 1 0 0)
 	SF-ADJUSTMENT "             (0=            )" '(200 0 250 1 10 0 0)
  	SF-TOGGLE     "                            (                           )" FALSE )

; Menu Register ----------------------------------------------------------------
(script-fu-menu-register "script-fu-cross-filter"
	"<Image>/Script-Fu/Photo")
