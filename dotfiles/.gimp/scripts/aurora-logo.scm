; aurora logo
;  
; --------------------------------------------------------------------
; version 1.0 by Michael Schalla 2003/02/17
; version 2.0 by Eric Lamarque 2004/08/20
; --------------------------------------------------------------------
;

(define (script-fu-aurora-logo inText inFont inFontSize inWhirl inWind1 inWind2 inBGColor inColor inAbsolute inImageWidth inImageHeight inFlatten)
  (let*
    (
      ; Definition unserer lokalen Variablen

      ; Erzeugen des neuen Bildes

      (img  ( car (gimp-image-new 10 10 RGB) ) )
      (theText)
      (theTextWidth)
      (theTextHeight)
      (imgWidth)
      (imgHeight)
      (theBufferX)
      (theBufferY)
      (theLayer2)
      (theLayer3)
      (theLayer4)
      (imgWidthR)
      (imgHeightR)

      ; Erzeugen einer neuen Ebene zum Bild
      (theLayer (car (gimp-layer-new img 10 10 RGB-IMAGE "Layer 1" 100 NORMAL) ) )

      (old-fg (car (gimp-palette-get-foreground) ) )
      (old-bg (car (gimp-palette-get-background) ) )
      ; Ende unserer lokalen Variablen
    )

    (gimp-image-add-layer img theLayer 0)

    ; zum Anzeigen des leeren Bildes
    ; (gimp-display-new img)

    (gimp-palette-set-background '(255 255 255) )
    (gimp-palette-set-foreground '(0 0 0) )

    (gimp-selection-all  img)
    (gimp-edit-clear     theLayer)
    (gimp-selection-none img)

    (set! theText (car (gimp-text-fontname img theLayer 0 0 inText 0 TRUE inFontSize PIXELS inFont)))

    (set! theTextWidth  (car (gimp-drawable-width  theText) ) )
    (set! theTextHeight (car (gimp-drawable-height theText) ) )

    (set! imgWidth (max (+ theTextWidth (* theTextHeight 2 ) (* (+ inWind2 (/ 100 (+ inWind1 1) ) ) 2.5) ) inImageWidth inImageHeight ) )
    (set! imgHeight imgWidth )

    (set! theBufferX      (/ (- imgWidth theTextWidth) 2) )
    (set! theBufferY      (/ (- imgHeight theTextHeight) 2) )

    (gimp-image-resize img imgWidth imgHeight 0 0)
    (gimp-layer-resize theLayer imgWidth imgHeight 0 0)

    (gimp-layer-set-offsets   theText theBufferX theBufferY)
    ;(gimp-floating-sel-anchor theText theLayer)
    (gimp-floating-sel-anchor theText)

    (set! theLayer2 (car (gimp-layer-copy theLayer TRUE)))
    (gimp-image-add-layer img theLayer2 0)

    (plug-in-whirl-pinch 1 img theLayer2 inWhirl 0.0 1.0)

    (set! theLayer3 (car (gimp-layer-copy theLayer2 TRUE)))
    (gimp-image-add-layer img theLayer3 0)

    (plug-in-wind 1 img theLayer2 inWind1 1 inWind2 0 0)
    (plug-in-wind 1 img theLayer3 inWind1 0 inWind2 0 0)

    (gimp-layer-set-mode theLayer3 DARKEN-ONLY)
		
		(set! theLayer4 (car (gimp-image-merge-down img theLayer3 0)))

    (plug-in-whirl-pinch 1 img theLayer4 (- 0 inWhirl) 0.0 1.0)
    (plug-in-gauss-iir 1 img theLayer4 3 TRUE TRUE)
    (plug-in-autostretch-hsv 0 img theLayer4)
    
    (plug-in-color-map 1 img theLayer4 '(128 128 128) '(255 255 255) inColor inBGColor 0)
    (gimp-invert theLayer4)

    (gimp-layer-set-mode theLayer4 DIFFERENCE)

    (plug-in-gauss-iir 1 img theLayer 1 TRUE TRUE)

    (set! imgWidthR inImageWidth )
    (set! imgHeightR inImageHeight )

  	(if (= inAbsolute FALSE)
      (set! imgWidthR (+ theTextWidth (* theTextHeight 2 ) (* (+ inWind2 (/ 100 (+ inWind1 1) ) ) 2.5) ) )
    )

  	(if (= inAbsolute FALSE)
      (set! imgHeightR ( + (* theTextHeight 3 ) (* (+ inWind2 (/ 100 (+ inWind1 1) ) ) 2.5) ) )
    )

    (set! theBufferX      (/ (- imgWidthR imgWidth) 2) )
    (set! theBufferY      (/ (- imgHeightR imgHeight) 2) )

    (gimp-image-resize img imgWidthR imgHeightR theBufferX theBufferY)

  	(if (= inFlatten TRUE)
      (gimp-image-flatten img)
  		()
  	)
	
    (gimp-palette-set-background old-bg)
    (gimp-palette-set-foreground old-fg)

    (gimp-display-new     img)
    (list  img theLayer theText)

    ; Bereinigen Dirty-Flag
    ;(gimp-image-clean-all img)

  )
)

(script-fu-register
  "script-fu-aurora-logo"
  "<Toolbox>/Xtns/Script-Fu/Logos/Aurora Borealis..."
  "Creates a text logo."
  "Michael Schalla"
  "Michael Schalla"
  "October 2002"
  ""
  SF-STRING "Text"             "Aurora Borealis"
  SF-FONT   "Font"             "-*-Arial Black-*-r-*-*-24-*-*-*-p-*-*-*"
  SF-VALUE  "Font size"        "50"
  SF-VALUE  "Whirl Amount"     "90"
  SF-ADJUSTMENT "Wind1"        '(10 0 50 1 1 0 1)
  SF-ADJUSTMENT "Wind2"        '(10 1 50 1 1 0 1)
  SF-COLOR "BG Color"          '(0 0 0)
  SF-COLOR "Color"             '(64 128 192)
  SF-TOGGLE "Absolute Size?"   FALSE
  SF-VALUE  "Image Width"      "300"
  SF-VALUE  "Image Height"     "100"
  SF-TOGGLE "Flatten Layers?"  FALSE
)

