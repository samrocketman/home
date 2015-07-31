; GIMP - The GNU Image Manipulation Program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;
;
; 
; Creates animated fire using the steps described in this tutorial by ash44455666
;
; http://www.gimptalk.com/forum/topic/Make-Moving-Fire-20158-1.html#159569
; The animation may be saved with the gif-plug-in.
;
; The script can be found under Filters > Animation > Animated Fire...
;
; The following settings can be modified:
;
; Number of frames (default is 25)
; Animation speed (default is 41 milliseconds)
; Image Width and Height (default width is 500 and height is 100)
; Foreground color (default is "burnt" orance)
; Background color (default is black)
; Add border (default is yes)
; Border width (default is 1)
; Border color (default is white)
;
; 5/3/2008 - added ability to add active layer from existing image to animation and blend
; the layer using the blend mode of the user's choosing.

; 5/6/2008 - added ability to use active layer as a mask to "cut out the flame" to match the mask.
; Just create a black or transparent layer and paint in white the areas you want to show through.
; The mask can work in two ways: the animation is transparent in all areas outside of the mask or
; the areas outside of the mask are completely filled with a color.  In both cases, you need to choose
; the mask background color.  In the case where the areas outside of the mask are transparent, the 
; mask background color will be useful in making the animation blend with your web page's background.
;
; 5/7/2008 - added option to "sandwich" the active layer between the flame layers and set the upper 
; flame layer's blend mode to screen to give the animation the appearance that the active layer is
; actually "in" the fire.  The idea was presented by Darth_Gimp at gimpdome.com.  Also, I modified
; the script to set the "noise" option a little lower when smaller images are created.  With the original
; settings, smaller images had "long" frames that were a little too unrealistic to me.  However, images that
; are much taller than wide may still have this result.
;
; Updated on October 3, 2008 to work in GIMP 2.6

; Define the Function

(define (script-fu-fire-anim 	img		 
				drawable
				counter
				speed
				width
				height
				useGradient
				gradient
				foregroundColor
				backgroundColor
				useActive
				blendOpt				
				displaceOpt
				xDisplace
				yDisplace
				maskColor
				addBorder
				borderWidth
				borderColor				
				)

; Declare the Variables

	(let* (
		    	(theSelection 0)
			(newImage 0)		    
			(activeLayer 0)
			(activeLayerCopy 0)
			(activeLayerHolder 0)
			(floatingSelection 0)
			(activeLayerBlendMode
				(cond 
				(( equal? blendOpt 0 ) NORMAL-MODE)
				(( equal? blendOpt 1 ) DISSOLVE-MODE)
				(( equal? blendOpt 2 ) MULTIPLY-MODE)
				(( equal? blendOpt 3 ) SCREEN-MODE)
				(( equal? blendOpt 4 ) OVERLAY-MODE)
				(( equal? blendOpt 5 ) DIFFERENCE-MODE)				
				(( equal? blendOpt 6 ) ADDITION-MODE)
				(( equal? blendOpt 7 ) SUBTRACT-MODE)
				(( equal? blendOpt 8 ) DARKEN-ONLY-MODE)
				(( equal? blendOpt 9 ) LIGHTEN-ONLY-MODE)
				(( equal? blendOpt 10 ) HUE-MODE)
				(( equal? blendOpt 11 ) SATURATION-MODE)
				(( equal? blendOpt 12 ) COLOR-MODE)
				(( equal? blendOpt 13 ) VALUE-MODE)
				(( equal? blendOpt 14 ) DIVIDE-MODE)
				(( equal? blendOpt 15 ) DODGE-MODE)
				(( equal? blendOpt 16 ) BURN-MODE)
				(( equal? blendOpt 17 ) HARDLIGHT-MODE)
				(( equal? blendOpt 18 ) SOFTLIGHT-MODE)
				(( equal? blendOpt 19 ) GRAIN-EXTRACT-MODE)
				(( equal? blendOpt 20 ) GRAIN-MERGE-MODE)
				)	
			)
			(baseLayer 0)
		    	(baseLayerCopy 0)
			(upperFlame 0)
		    	(lowerFlame 0)
			(upperFlameCopy 0)
			(lowerFlameCopy 0)
			(layerName 0)
		    	(remainingFrames counter 0)
			(offset 0)
			(step 0)
			(frameNum 1)
            	(borderLayer 0)
			(layerMask 0)
			(xNoise 0)	
	)

(gimp-context-push)

(if (= useActive 4)
	(begin
	(set! newImage (car (gimp-image-new width height RGB)))
	(set! theSelection (car (gimp-selection-save img)))
	(gimp-selection-none img)
	)
)
  
(if (or (= useActive 0) (= useActive 1))
    	(begin
	(set! activeLayer (car (gimp-image-get-active-layer img)))
	(set! theSelection (car (gimp-selection-save img)))
	(gimp-selection-none img)
	(set! width (car (gimp-drawable-width activeLayer)))
	(set! height (car (gimp-drawable-height activeLayer)))
	(set! activeLayer (car (gimp-edit-copy activeLayer)))
	(set! newImage (car (gimp-image-new width height RGB)))
	(set! activeLayerHolder (car (gimp-layer-new newImage width height RGBA-IMAGE 	"Active Layer" 100 NORMAL-MODE)))
	(gimp-drawable-fill activeLayerHolder TRANSPARENT-FILL)	
	(gimp-image-add-layer newImage activeLayerHolder -1)
	(set! floatingSelection (car (gimp-edit-paste activeLayerHolder TRUE))) 	
	(gimp-floating-sel-anchor floatingSelection)	
	(set! activeLayer (car (gimp-image-get-active-layer newImage)))
	)
)

(if (or (= useActive 2) (= useActive 3))
    	(begin
	(set! activeLayer (car (gimp-image-get-active-layer img)))
	(set! theSelection (car (gimp-selection-save img)))
	(gimp-selection-none img)
	(set! width (car (gimp-drawable-width activeLayer)))
	(set! height (car (gimp-drawable-height activeLayer)))
	(set! activeLayer (car (gimp-edit-copy activeLayer)))
	(set! newImage (car (gimp-image-new width height RGB)))
	)
)

(gimp-image-undo-disable newImage)
(set! baseLayer (car (gimp-layer-new newImage width height RGBA-IMAGE "Base Layer" 100 NORMAL-MODE)))
(gimp-image-add-layer newImage baseLayer -1) 
(gimp-context-set-foreground foregroundColor)
(gimp-context-set-background backgroundColor)      
(gimp-edit-blend baseLayer FG-BG-RGB-MODE NORMAL-MODE GRADIENT-LINEAR 100 0 REPEAT-NONE FALSE FALSE 1 0 TRUE 0 height 0 0)

(set! lowerFlame (car (gimp-layer-copy baseLayer TRUE)))
(gimp-image-add-layer newImage lowerFlame -1)

(if (< width 400)
    (set! xNoise 6.0)
    (set! xNoise 13.0)
)

(plug-in-solid-noise RUN-NONINTERACTIVE newImage lowerFlame 1 0 (rand) (rand) xNoise 5.3)
(set! upperFlame (car (gimp-layer-copy lowerFlame TRUE)))
(gimp-image-add-layer newImage upperFlame -1)
(plug-in-solid-noise RUN-NONINTERACTIVE newImage upperFlame 1 0 (rand) (rand) xNoise 2.0)
(set! step (* -1 (/ height counter))) 

(while (> counter 0)
	
(set! baseLayerCopy (car (gimp-layer-copy baseLayer TRUE)))
(set! layerName (string-append "Frame " (number->string frameNum) " (" (number->string speed) "ms)" " (replace)"))
(gimp-image-add-layer newImage baseLayerCopy -1)
(gimp-drawable-set-name baseLayerCopy layerName)
(set! lowerFlameCopy (car (gimp-layer-copy lowerFlame TRUE)))
(gimp-image-add-layer newImage lowerFlameCopy -1)
(gimp-drawable-offset lowerFlameCopy TRUE OFFSET-BACKGROUND 0.0 offset)
(gimp-layer-set-mode lowerFlameCopy OVERLAY-MODE)
(set! upperFlameCopy (car (gimp-layer-copy upperFlame TRUE)))
(gimp-image-add-layer newImage upperFlameCopy -1)
(gimp-drawable-offset upperFlameCopy TRUE OFFSET-BACKGROUND 0.0 offset)
(gimp-layer-set-mode upperFlameCopy DODGE-MODE)

(gimp-image-set-active-layer newImage lowerFlameCopy)
(gimp-image-merge-down newImage lowerFlameCopy CLIP-TO-IMAGE)
(gimp-image-set-active-layer newImage upperFlameCopy)
(gimp-image-merge-down newImage upperFlameCopy CLIP-TO-IMAGE)
(set! baseLayerCopy (car (gimp-image-get-active-layer newImage)))
(if (= useGradient TRUE)
      (begin
      (gimp-context-set-gradient gradient)
	(plug-in-gradmap RUN-NONINTERACTIVE newImage baseLayerCopy)
	)
)

(if (= useActive 0)
	(begin
	(set! activeLayerCopy (car (gimp-layer-copy activeLayer TRUE)))
	(gimp-image-add-layer newImage activeLayerCopy -1)
	(gimp-layer-set-mode activeLayerCopy activeLayerBlendMode)
		(if (= displaceOpt TRUE)	
			(plug-in-displace RUN-NONINTERACTIVE newImage activeLayerCopy xDisplace yDisplace TRUE TRUE baseLayerCopy baseLayerCopy 1)	
		)
	(gimp-image-merge-down newImage activeLayerCopy CLIP-TO-IMAGE)
	)
)

(if (= useActive 1)
	(begin
	(set! activeLayerCopy (car (gimp-layer-copy activeLayer TRUE)))
	(gimp-image-add-layer newImage activeLayerCopy -1)
		(if (= displaceOpt TRUE)	
			(plug-in-displace RUN-NONINTERACTIVE newImage activeLayerCopy xDisplace yDisplace TRUE TRUE baseLayerCopy baseLayerCopy 1)	
		)
	(set! baseLayerCopy (car (gimp-layer-copy baseLayerCopy TRUE)))
	(gimp-image-add-layer newImage baseLayerCopy -1)
	(gimp-layer-set-mode baseLayerCopy SCREEN-MODE)
	(gimp-image-set-active-layer newImage activeLayerCopy)
	(gimp-image-merge-down newImage activeLayerCopy CLIP-TO-IMAGE)
	(gimp-image-set-active-layer newImage baseLayerCopy)
	(gimp-image-merge-down newImage baseLayerCopy CLIP-TO-IMAGE)
	)
)	

(if (= useActive 2)
	(begin
	(set! layerMask (car (gimp-layer-create-mask baseLayerCopy ADD-BLACK-MASK)))
	(gimp-layer-add-mask baseLayerCopy layerMask)
	(set! floatingSelection (car (gimp-edit-paste layerMask TRUE)))
	(gimp-floating-sel-anchor floatingSelection)
		(if (= displaceOpt TRUE)	
			(plug-in-displace RUN-NONINTERACTIVE newImage layerMask xDisplace yDisplace TRUE TRUE baseLayerCopy baseLayerCopy 1)	
		)
	(gimp-layer-remove-mask baseLayerCopy MASK-APPLY)
	(gimp-context-set-background maskColor) 
	(plug-in-semiflatten RUN-NONINTERACTIVE newImage baseLayerCopy)
	)
)

(if (= useActive 3)
	(begin
	(set! layerMask (car (gimp-layer-create-mask baseLayerCopy ADD-BLACK-MASK)))
	(gimp-layer-add-mask baseLayerCopy layerMask)
	(set! floatingSelection (car (gimp-edit-paste layerMask TRUE)))
	(gimp-floating-sel-anchor floatingSelection)
		(if (= displaceOpt TRUE)	
			(plug-in-displace RUN-NONINTERACTIVE newImage layerMask xDisplace yDisplace TRUE TRUE baseLayerCopy baseLayerCopy 1)	
		)
	(gimp-layer-remove-mask baseLayerCopy MASK-APPLY)
	(gimp-context-set-background maskColor) 
	(gimp-layer-flatten baseLayerCopy)
	)
)

(set! offset (+ offset step))
(set! frameNum (+ frameNum 1))
(set! counter (- counter 1))



; Adds a border layer if chosen by the user with the values set

(if (= addBorder TRUE)
    (begin
    (set! borderLayer (car (gimp-layer-copy baseLayer TRUE)))
    (gimp-image-add-layer newImage borderLayer -1)
    (gimp-selection-all newImage)
    (gimp-context-set-foreground borderColor)
    (gimp-drawable-fill borderLayer FOREGROUND-FILL)
    (gimp-selection-shrink newImage borderWidth)
    (gimp-edit-clear borderLayer)
    (gimp-selection-none newImage)
    (gimp-image-merge-down newImage borderLayer CLIP-TO-IMAGE) 
    )
)

) ; goes with while

; Removes the original layer from the stack because it's no longer needed  
  
(gimp-image-remove-layer newImage baseLayer) 
(gimp-image-remove-layer newImage upperFlame) 
(gimp-image-remove-layer newImage lowerFlame) 

(if (or (= useActive 0) (= useActive 1))
	(gimp-image-remove-layer newImage activeLayer)
)

(gimp-image-undo-enable newImage)

(gimp-selection-load theSelection)
(gimp-image-remove-channel img theSelection)

(gimp-context-pop)

(gimp-displays-flush)

; Displays the final animation

(gimp-display-new newImage)
(gimp-image-set-active-layer img drawable)
  )
)

(script-fu-register "script-fu-fire-anim"
  "<Image>/Filters/Animation/Animators/Animated Fire..."
  "Creates an animated fire effect"
  "Art Wade"
  "Art Wade"
  "October 3, 2008"
  "RGB*"
  SF-IMAGE       	"Image" 0
  SF-DRAWABLE    	"Drawable" 0
  SF-ADJUSTMENT 	"Number of frames" '(25 1 50 1 10 0 1)
  SF-ADJUSTMENT 	"Animation Speed (in ms)" '(41 10 500 1 1 0 1)
  SF-ADJUSTMENT 	"Image Width" '(500 50 2500 1 1 0 1)
  SF-ADJUSTMENT 	"Image Height" '(100 50 2500 1 1 0 1)
  SF-TOGGLE       "Use Gradient?" TRUE
  SF-GRADIENT     "Gradient" 		"Incandescent"
  SF-COLOR      	"Desired Flame Foreground Color (Only used if gradient is not applied)" '(255 132 0)
  SF-COLOR	  	"Desired Flame Background Color (Only used if gradient is not applied)" '(0 0 0)
  SF-OPTION		"Add Active Layer to Animation?" 	'("Above animation using blend mode below"
									"Place render between two fire layers and set upper fire layer mode to Screen"
									"As a mask; transparency around mask; use mask background color to blend edges"
									"As a mask; fill image with mask background color"
									"Don't use active layer in animation")

  SF-OPTION		"Blend Mode for Active Layer" 		'("NORMAL-MODE" 
									"DISSOLVE-MODE"
									"MULTIPLY-MODE"
									"SCREEN-MODE"
									"OVERLAY-MODE"
									"DIFFERENCE-MODE"
									"ADDITION-MODE"
									"SUBTRACT-MODE"
									"DARKEN-ONLY-MODE"
									"LIGHTEN-ONLY-MODE"
									"HUE-MODE"
									"SATURATION-MODE"
									"COLOR-MODE"
									"VALUE-MODE"
									"DIVIDE-MODE"
									"DODGE-MODE"
									"BURN-MODE"
									"HARDLIGHT-MODE"
									"SOFTLIGHT-MODE"
									"GRAIN-EXTRACT-MODE"
									"GRAIN-MERGE-MODE")
  SF-TOGGLE       "Move active layer with flames?" TRUE
  SF-ADJUSTMENT   "Move amount along x-axis" '(5 -9999 9999 1 1 0 1)
  SF-ADJUSTMENT   "Move amount along y-axis" '(5 -9999 9999 1 1 0 1)  
  SF-COLOR      	"Mask Background Color" 		'(0 0 0)
  SF-TOGGLE       "Add Border?" TRUE
  SF-ADJUSTMENT   "Border Width" '(1 1 10 1 1 0 1)
  SF-COLOR        "Border Color" '(255 255 255)
)


                         
