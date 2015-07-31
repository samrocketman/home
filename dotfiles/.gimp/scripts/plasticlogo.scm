;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; plasticlogo.scm
; Version 0.6 (For The Gimp 2.0 and 2.2)
; A Script-Fu that create a Polished Plastic Text or Shape
;
; Copyright (C) 2004 Denis Bodor <lefinnois@lefinnois.net>
;
; This program is free software; you can redistribute it and/or 
; modify it under the terms of the GNU General Public License   
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (apply-plastic-logo-effect	img
					basetext
					back-color
					type)
  (let* ((width (car (gimp-drawable-width basetext)))
	 (height (car (gimp-drawable-height basetext)))
	 (fond (car (gimp-layer-new   img
				      width height RGB-IMAGE
				      "Background" 100 NORMAL-MODE)))
	 (olight (car (gimp-layer-new img
				      width height RGBA-IMAGE
				      "Light Outline" 90 SCREEN-MODE)))
	 (border (car (gimp-layer-new img
				      width height RGBA-IMAGE
				      "Border" 100 NORMAL-MODE)))
	 (refl (car (gimp-layer-new   img
				      width height RGBA-IMAGE
				      "Refl" 67 NORMAL-MODE)))
	 (mapeux (car (gimp-layer-new img
				      width height RGBA-IMAGE
				      "Mapper" 100 NORMAL-MODE)))
	 (shad (car (gimp-layer-new   img
				      width height RGBA-IMAGE
				      "Shadow" 100 NORMAL-MODE)))
	 (chantext)
	 (basetextmask)
	 (reflmask)
	 )
 

    (gimp-context-push)

    ; filling back with background
    (gimp-context-set-background back-color)
    (gimp-selection-none img)
    (script-fu-util-image-resize-from-layer img basetext)
    (gimp-image-add-layer img fond 1)
    (gimp-edit-clear fond)
    
    ; composite text and channel
    (gimp-selection-layer-alpha basetext)
    (set! chantext (car (gimp-selection-save img)))
    (set! basetextmask (car (gimp-layer-create-mask basetext ADD-ALPHA-MASK)))
    (gimp-layer-add-mask basetext basetextmask)
    (gimp-selection-all img)
    (if (= type 0) (gimp-edit-fill basetext FOREGROUND-FILL))
    (if (= type 1) (gimp-edit-bucket-fill basetext PATTERN-BUCKET-FILL 0 100 0 0 1 1))
    (if (= type 2) (gimp-edit-blend basetext 
				    CUSTOM-MODE		;  
				    NORMAL-MODE		; 
				    GRADIENT-LINEAR	; gradient type
				    100			; opacity
				    0			; offset
				    REPEAT-NONE		; repeat
				    FALSE		; reverse
				    FALSE		; supersampling
				    0 0			; 
				    FALSE		; dithering
				    0 0			; x1 y1
				    width		; y1
				    height		; x2
				    ))
    
    ; Adding light effect on edge
    (gimp-selection-none img)
    (gimp-image-add-layer img olight 0)
    (gimp-edit-clear olight)
    (gimp-selection-load chantext)
    (gimp-selection-shrink img 3)
    (gimp-selection-invert img)
    (gimp-context-set-foreground '(255 255 255))
    (gimp-edit-fill olight FOREGROUND-FILL)
    (gimp-selection-none img)
    (plug-in-gauss-rle2 1 img olight 18 18)
    (gimp-selection-load chantext)
    (gimp-selection-invert img)
    (gimp-edit-cut olight)

    ; creating black border
    (gimp-image-add-layer img border -1)
    (gimp-edit-clear border)
    (gimp-context-set-foreground '(0 0 0))
    (gimp-selection-load chantext)
    (gimp-edit-fill border FOREGROUND-FILL)
    (gimp-selection-shrink img 1)
    (gimp-edit-cut border)

    ; adding light reflect
    (gimp-image-add-layer img refl -1)
    (gimp-edit-clear refl)
    (gimp-ellipse-select img 
			 (- 0 (/ width 2))
			 (- 0 height)
			 (* width 2)
			 (* height 1.54)
			 2 
			 TRUE
			 0
			 0)
    (gimp-context-set-foreground '(255 255 255))
    (gimp-edit-blend refl
		     FG-TRANSPARENT-MODE
		     NORMAL-MODE
		     GRADIENT-LINEAR
		     100
		     0
		     REPEAT-NONE
		     FALSE
		     FALSE
		     0
		     0
		     FALSE
		     (/ width 2)
		     (* height 0.54)
		     (/ width 2)
		     (* height 0.05))
    (gimp-selection-load chantext)
    (set! reflmask (car (gimp-layer-create-mask refl ADD-SELECTION-MASK)))
    (gimp-layer-add-mask refl reflmask)

    ; creating bumpmap map
    (gimp-image-add-layer img mapeux -1)
    (gimp-edit-clear mapeux)
    (gimp-selection-none img)
    (gimp-context-set-foreground '(0 0 0))
    (gimp-edit-fill mapeux FOREGROUND-FILL)
    (gimp-selection-load chantext)
    (gimp-selection-shrink img 5)
    (gimp-context-set-foreground '(255 255 255))
    (gimp-edit-fill mapeux FOREGROUND-FILL)
    (gimp-selection-none img)
    (plug-in-gauss-rle2 1 img mapeux 18 18)

    ; bumpmapping:displacing reflect to follow shape
    (plug-in-displace 1
		      img
		      refl
		      1.5
		      1.5
		      TRUE
		      TRUE
		      mapeux
		      mapeux
		      0)
    (gimp-image-remove-layer img mapeux)    
    
    ; back shadow
    (gimp-image-add-layer img shad 4)
    (gimp-edit-clear shad)
    (gimp-selection-load chantext)
    (gimp-selection-translate img 0 12)
    (gimp-context-set-foreground '(50 50 50))
    (gimp-edit-fill shad FOREGROUND-FILL)
    (gimp-selection-none img)
    (plug-in-gauss-rle2 1 img shad 15 15)
    
    ; correcting resizing effect on background
    (gimp-context-set-foreground back-color)
    (gimp-layer-resize-to-image-size fond)
    (gimp-edit-fill fond FOREGROUND-FILL)
    
    (gimp-context-pop)))



(define (script-fu-plastic-logo-alpha img
				      text-layer
				      fond-color
				      type
				      )
  (begin
    (gimp-image-undo-disable img)
    (apply-plastic-logo-effect img text-layer fond-color type)
    (gimp-image-undo-enable img)
    (gimp-displays-flush)))



(script-fu-register 	"script-fu-plastic-logo-alpha"
			"Polished Plastic..."
			"Create a polished plastic logo"
			"Denis Bodor <lefinnois@lefinnois.net>"
			"Denis Bodor"
			"03/31/2005"
			""
			SF-IMAGE	"Image"			0
			SF-DRAWABLE	"Drawable"		0
			SF-COLOR "Background color" '(255 255 255)
			SF-OPTION "Color" '("Foreground color"
						"Pattern"
						"Gradient"))

(script-fu-menu-register "script-fu-plastic-logo-alpha"
			 "<Image>/Script-Fu/Alpha to Logo")

(define (script-fu-plastic-logo2		font
					text
					fond-color
					size
					type		; Color=0 Pattern=1 Gradient=2
					)
  
  (let* ((img (car (gimp-image-new 256 256 RGB)))	; nouvelle image -> img
	 (border (/ size 4))
	 (text-layer (car (gimp-text-fontname img
					      -1 0 0 text border TRUE 
					      size PIXELS font)))
	 (width (car (gimp-drawable-width text-layer)))
	 (height (car (gimp-drawable-height text-layer)))
	 )
    
    (gimp-image-undo-disable img)
    (gimp-drawable-set-name text-layer text)
    (apply-plastic-logo-effect img text-layer fond-color type)
    (gimp-image-undo-enable img)
    (gimp-display-new img)    
    ))


(script-fu-register 	"script-fu-plastic-logo2"
			"Polished Plastic"
			"Create a polished plastic logo"
			"Denis Bodor <lefinnois@lefinnois.net>"
			"Denis Bodor"
			"03/31/2005"
			""
            SF-FONT "Font" "Blippo Heavy"
            SF-STRING "Text" "PLASTIC FUN"
            SF-COLOR "Background color" '(255 255 255)
            SF-ADJUSTMENT "Font size (pixels)" '(150 2 1000 1 10 0 1)
            SF-OPTION "Font color" '("Foreground color" "Pattern" "Gradient"))

;(script-fu-menu-register "script-fu-plastic-logo2"
;			 "<Toolbox>/Xtns/Render/Logos")

(script-fu-menu-register "script-fu-plastic-logo2"
			 "<Toolbox>/Xtns/Script-Fu/Extra Logos")