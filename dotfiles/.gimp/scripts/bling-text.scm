; Bling Text V1.2 (11-2007)
; Create animated or static bling text with drop shadow
;
; Created by Scott Mosteller 
; Bling Graphic Animations and Patterns by Tonya Marshal
;
;********************************* IMPORTANT ****************************************
; This script requires a set of patterns that are included in the zip file (/patterns)
;
; Copy these patterns to your local pattern folder in order to use this script
;**************************************************************************************
;
; Checking the animate toggle will direct script to generate 3 text layers with the selected font
; The text will be filled with the selected pattern and bling type
;
; Each layer will be shadowed and semifattened with the background color, for use as an animated .GIF
; All that is required as this point is to simply save the image as an animated .GIF
;
; Leaving the animate toggle unchecked will direct the script to generate a static image
; The static images will contain one shadowed text layer, semifattened, along the background layer. 
;
; Selecting "Raw Layers Only" returns only the raw layers. To more easily work with the raw layers,
; Bring up the layers dialog, right click on "Background" layer and select "Alpha to selection"        
; Then, simply crop the image. You are now ready to work with the script's raw layers.
; No semi-flatten function is applied to the raw image layers
;
;
; Comments directed to http://www.upstateforums.com (computer graphics and art section)
;
; Compatible with all Gimp Versions 2.x - Enjoy!
;
; ------------
;| Change Log |
; ------------ 
; V1.0 - Initial Release
; V1.1 - Added shadow x/y offset, Shadow Opacity, Autocrop and Raw Layers Options
; V1.2 - Added four new Bling Patterns              
;
;
;Main Procedure 
;
; options definitions
;
(define (script-fu-bling-text text
			       size
			       font
			       text-color
                               ssize
                               bg-color
                               shadow-color
                               shx
                               shy
                               sho
                               stype
                               lpat
                               lani
                               raw)

  (let* ((img (car (gimp-image-new 256 256 RGB)))
         (tmp (car (gimp-context-set-foreground text-color)))
	 (text-layer (car (gimp-text-fontname img -1 0 0 text 10 TRUE size PIXELS font)))  ;Create text layers
	 (text-layer2 (car (gimp-text-fontname img -1 0 0 text 10 TRUE size PIXELS font)))
         (text-layer3 (car (gimp-text-fontname img -1 0 0 text 10 TRUE size PIXELS font)))
        )
;
; Main Body
;

    (gimp-image-undo-disable img) 
    (apply-bling-text-effect img text-layer text-layer2 text-layer3 bg-color text-color shadow-color shx shy sho stype lpat ssize lani raw)
    (gimp-selection-none img)
    (gimp-image-undo-enable img)
    (gimp-display-new img)))
;
; End of Main body
;
;
; User Options
;
(script-fu-register "script-fu-bling-text"
		    _"_Bling text..."
		    "Creates Bling text with a drop shadow"
		    "Scott Mosteller"
		    "Scott Mosteller"
		    "2007"
		    ""
		    SF-STRING     _"Text"               "UFSC"
		    SF-ADJUSTMENT _"Font size (pixels)" '(200 2 1000 1 10 0 1)
		    SF-FONT       _"Font"               "Arial Bold"
		    SF-COLOR      _"Stroke color"       '(115 8 8)
                    SF-ADJUSTMENT _"Stroke (pixels)"    '(2 0 10 1 1 0 1)
		    SF-COLOR      _"Background color"   '(255 255 255)
		    SF-COLOR      _"Shadow color"       '(0 0 0)
                    SF-ADJUSTMENT _"Shadow Offset X"    '(-5 -99 99 1 1 0 1)
                    SF-ADJUSTMENT _"Shadow Offset Y"    '(5 -99 99 1 1 0 1)
                    SF-ADJUSTMENT _"Shadow Opacity"     '(60 1 100 1 1 0 1)
                    SF-OPTION     _"Sparkle Type"       '("Sparkle" "Pixel-Bling" "Tiny Stars" "Star-Blur" "Whitenoise" "Bubbles" "Bubble Fizz" "Bling Stew" "Bling Stew No Fizz")
                    SF-PATTERN    _"Fill Pattern"       "Wacky Whirled stuff"
                    SF-TOGGLE     _"Animate?"           FALSE
                    SF-TOGGLE     _"Raw Layers Only?"   FALSE)
;
;
; Apply Bing Text Procedure
;
; Define procedure and declare local variables
;
(define (apply-bling-text-effect img
				  logo-layer
                                  logo-layer2
                                  logo-layer3
				  bg-color
				  text-color
                                  shadow-color
                                  shx
                                  shy
                                  sho
                                  stype
                                  lpat
                                  ssize
                                  lani
                                  raw)
  (let* ((width (car (gimp-drawable-width logo-layer)))
	 (height (car (gimp-drawable-height logo-layer)))
	 (bg-layer (car (gimp-layer-new img width height RGBA-IMAGE "Background" 100 NORMAL-MODE)))
	 (shadow-layer (car (gimp-layer-new img width height RGBA-IMAGE "Shadow" sho NORMAL-MODE)))
         (shadow-layer2 (car (gimp-layer-new img width height RGBA-IMAGE "Shadow1" sho NORMAL-MODE)))
         (shadow-layer3 (car (gimp-layer-new img width height RGBA-IMAGE "Shadow2" sho NORMAL-MODE)))
         (tmpl1 0) 
         (tmpl2 0)
         (tmpl3 0)
         (tmps1 0)
         (tmps2 0)
         (tmps3 0)
   )

;
; Push context to save
;
   (gimp-context-push)
   (gimp-selection-none img)
   (script-fu-util-image-resize-from-layer img logo-layer)
;
; Add a background layer
;

   (gimp-image-add-layer img bg-layer 2)
   (gimp-context-set-foreground text-color)
;   (gimp-context-set-background bg-color)
;   (gimp-edit-fill bg-layer BACKGROUND-FILL)

;
; Create shadow layer 1
;
   (gimp-image-add-layer img shadow-layer -1)
   (gimp-edit-clear shadow-layer)
   (gimp-selection-layer-alpha logo-layer)
   (gimp-context-set-background '(0 0 0))
   (gimp-selection-feather img 5)
   (gimp-context-set-background shadow-color)
   (gimp-edit-fill shadow-layer BACKGROUND-FILL)
   (gimp-layer-translate shadow-layer shx shy)
   (gimp-image-resize-to-layers img)

;
; Resize and fill BG layer
;
   (gimp-layer-resize-to-image-size bg-layer)
   (gimp-selection-none img)
   (gimp-context-set-background bg-color)
   (gimp-edit-fill bg-layer BACKGROUND-FILL)

;
; Create shadow layer 2
;
   (gimp-selection-none img)
   (gimp-image-add-layer img shadow-layer2 1)
   (gimp-layer-resize-to-image-size shadow-layer2)
   (gimp-edit-clear shadow-layer2)
   (gimp-selection-layer-alpha logo-layer2)
   (gimp-context-set-background '(0 0 0))
   (gimp-selection-feather img 5)
   (gimp-context-set-background shadow-color)
   (gimp-edit-fill shadow-layer2 BACKGROUND-FILL)
   (gimp-layer-translate shadow-layer2 shx shy)
   (gimp-image-resize-to-layers img)


;
; Create shadow layer 3
;
   (gimp-selection-none img)
   (gimp-image-add-layer img shadow-layer3 1)
   (gimp-layer-resize-to-image-size shadow-layer3)
   (gimp-edit-clear shadow-layer3)
   (gimp-selection-layer-alpha logo-layer3)
   (gimp-context-set-background '(0 0 0))
   (gimp-selection-feather img 5)
   (gimp-context-set-background shadow-color)
   (gimp-edit-fill shadow-layer3 BACKGROUND-FILL)
   (gimp-image-raise-layer img shadow-layer3)
   (gimp-layer-translate shadow-layer3 shx shy)
   (gimp-image-resize-to-layers img)

;
; Fill text layers with selected pattern
;
  (gimp-by-color-select logo-layer text-color 15 2 TRUE FALSE 10 FALSE)
  (gimp-selection-shrink img ssize)
  (gimp-context-set-pattern lpat)
  (gimp-edit-bucket-fill logo-layer 2 0 100 0 0 0 0)
  (gimp-edit-bucket-fill logo-layer2 2 0 100 0 0 0 0)
  (gimp-edit-bucket-fill logo-layer3 2 0 100 0 0 0 0)

;
; Determine and set bling type
;
(if (= stype 0)
   (begin
     (set! tmps1 "Sparkle1")
     (set! tmps2 "Sparkle2")
     (set! tmps3 "Sparkle3")
    ))

(if (= stype 1)
   (begin
     (set! tmps1 "Single pixel bling1")
     (set! tmps2 "Single pixel bling2")
     (set! tmps3 "Single pixel bling3")
    ))
(if (= stype 2)
   (begin
     (set! tmps1 "Little Stars 1")
     (set! tmps2 "Little Stars 2")
     (set! tmps3 "Little Stars 3")
    ))
(if (= stype 3)
   (begin
     (set! tmps1 "Little Stars blurred1")
     (set! tmps2 "Little Stars blurred2")
     (set! tmps3 "Little Stars blurred3")
    ))
(if (= stype 4)
   (begin
     (set! tmps1 "WhiteNoise1")
     (set! tmps2 "Whitenoise2")
     (set! tmps3 "Whitenoise3")
    ))
(if (= stype 5)
   (begin
     (set! tmps1 "Bubbles 1")
     (set! tmps2 "Bubbles 2")
     (set! tmps3 "Bubbles 3")
    ))
(if (= stype 6)
   (begin
     (set! tmps1 "Bubble Fizz 1")
     (set! tmps2 "Bubble Fizz 2")
     (set! tmps3 "Bubble Fizz 3")
    ))
(if (= stype 7)
   (begin
     (set! tmps1 "Bling Stew 1")
     (set! tmps2 "Bling Stew 2")
     (set! tmps3 "Bling Stew 3")
    ))
(if (= stype 8)
   (begin
     (set! tmps1 "Bling Stew No Fizz 1")
     (set! tmps2 "Bling Stew No Fizz 2")
     (set! tmps3 "Bling Stew No Fizz 3")
    ))
;
; Fill text with bling patterns
;
 (gimp-context-set-pattern tmps1)
 (gimp-edit-bucket-fill logo-layer 2 0 100 0 0 0 0)
 (gimp-context-set-pattern tmps2)
 (gimp-edit-bucket-fill logo-layer2 2 0 100 0 0 0 0)
 (gimp-context-set-pattern tmps3)
 (gimp-edit-bucket-fill logo-layer3 2 0 100 0 0 0 0)

;
; Arange the layers
;
  (gimp-image-raise-layer-to-top img logo-layer3)
  (gimp-image-raise-layer-to-top img shadow-layer2)
  (gimp-image-raise-layer-to-top img logo-layer2)
  (gimp-image-raise-layer-to-top img shadow-layer)
  (gimp-image-raise-layer-to-top img logo-layer)

;
; Merge, Semi-flatten and Name layers only if Raw layers option not selected
;
(if (= raw FALSE)
  (begin
  (set! tmpl3 (car (gimp-image-merge-down img logo-layer3 0)))
  (gimp-drawable-set-name tmpl3 "TextLayer3")
  (gimp-selection-none img)
  (gimp-context-set-background bg-color)
  (gimp-image-set-active-layer img tmpl3)
  (plug-in-semiflatten 1 img tmpl3)
;
  (set! tmpl2 (car (gimp-image-merge-down img logo-layer2 0)))
  (gimp-drawable-set-name tmpl2 "TextLayer2")
  (gimp-selection-none img)
  (gimp-context-set-background bg-color)
  (gimp-image-set-active-layer img tmpl2)
  (plug-in-semiflatten 1 img tmpl2)
;
  (set! tmpl1 (car (gimp-image-merge-down img logo-layer 0)))
  (gimp-drawable-set-name tmpl1 "TextLayer1")
  (gimp-selection-none img)
  (gimp-context-set-background bg-color)
  (gimp-image-set-active-layer img tmpl1)
  (plug-in-semiflatten 1 img tmpl1)
  (plug-in-autocrop 1 img tmpl1)
 ))

;
; Check animate flag and remove layers as needed 
;

(if (and (= lani FALSE) (= raw FALSE))
  (begin
   (gimp-image-remove-layer img tmpl2)
   (gimp-image-remove-layer img tmpl3)
   )
    (if (= raw FALSE) (gimp-image-remove-layer img bg-layer))
)
;
; Make Background layer current if Raw Layers option is selected 
;
(if (= raw TRUE)
  (begin
   (gimp-image-set-active-layer img bg-layer)
   ))
;
; Restore context & done
;
   (gimp-context-pop)))
;
; End of Apply Procedue
;
;
; Register Script in Gimp
;
(script-fu-menu-register "script-fu-bling-text"
			 _"<Toolbox>/Xtns/Script-Fu/Logos")
