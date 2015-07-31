;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; aquabou.scm
; Version 0.4.1 (For The Gimp 2.0 and 2.2)
; A Script-Fu that create a Aqua Style Button
;
; Copyright (C) 2005 Denis Bodor <lefinnois@lefinnois.net>
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

(define (make-aqua-selection		img
					width)
  (let* ((rectwidth (- width 256))
	 (ellistartx (- width 216))
	 )
    (gimp-ellipse-select img 40 40 176 176 2 TRUE 0 0)
    (gimp-ellipse-select img ellistartx 40 176 176 0 TRUE 0 0)
    (gimp-rect-select img 128 40 rectwidth 176 0 0 0)
    ))

(define (apply-aqua-logo-effect		img
					coulfg
					coulbg
					dawidth)
  (let* ((width (car (gimp-image-width img)))
	 (height (car (gimp-image-height img)))
	 (fond (car (gimp-layer-new	img
					width height RGB-IMAGE
					"Background" 100 NORMAL-MODE)))
	 (base (car (gimp-layer-new	img
					width height RGBA-IMAGE
					"Base" 90 NORMAL-MODE)))
	 (ombre (car (gimp-layer-new	img
					width height RGBA-IMAGE
					"Shadow" 70 NORMAL-MODE)))
	 (reflh (car (gimp-layer-new	img
					width height RGBA-IMAGE
					"Top Reflect" 80 SCREEN-MODE)))
	 (lum (car (gimp-layer-new	img
					width height RGBA-IMAGE
					"light" 100 OVERLAY-MODE)))
	 (cote (car (gimp-layer-new	img
					width height RGBA-IMAGE
					"Refracting" 70 OVERLAY-MODE)))
	 (maskbase)
	 (maskombre)
	 (chacha)
	 (floflo)
	 )

    
    (gimp-context-push)

    (gimp-image-add-layer img reflh 0)
    (gimp-image-add-layer img cote 1)
    (gimp-image-add-layer img lum 2)
    (gimp-image-add-layer img base 3)
    (gimp-image-add-layer img ombre 4)
    (gimp-image-add-layer img fond 5)

    (gimp-edit-clear reflh)
    (gimp-edit-clear cote)
    (gimp-edit-clear lum)
    (gimp-edit-clear base)
    (gimp-edit-clear ombre)
    (gimp-edit-clear fond)

    (gimp-context-set-foreground coulbg)
    (gimp-edit-fill fond FOREGROUND-FILL)

    (set! maskbase (car (gimp-layer-create-mask base ADD-WHITE-MASK)))

    (gimp-layer-add-mask base maskbase)
    (gimp-edit-clear maskbase)

    (gimp-context-set-foreground '(255 255 255))
    (gimp-edit-fill maskbase FOREGROUND-FILL)
    (make-aqua-selection img width)
    (gimp-context-set-foreground coulfg)
    (gimp-edit-fill base FOREGROUND-FILL)

    (gimp-selection-shrink img 58)
    (gimp-context-set-foreground '(160 160 160))
    (gimp-edit-fill maskbase FOREGROUND-FILL)
    (gimp-selection-none img)
    (plug-in-gauss-rle2 1 img maskbase 74 74)

    (make-aqua-selection img width)
    (gimp-selection-translate img 0 50)
    (gimp-context-set-foreground coulfg)
    (gimp-edit-fill ombre FOREGROUND-FILL)
    (gimp-selection-none img)
    (plug-in-gauss-rle2 1 img ombre 44 44)
    (gimp-context-set-foreground coulfg)

    (set! maskombre (car (gimp-layer-create-mask ombre ADD-ALPHA-MASK)))
    (gimp-layer-add-mask ombre maskombre)
    (gimp-edit-clear maskombre)
    (gimp-context-set-foreground '(0 0 0))
    (gimp-edit-fill maskombre FOREGROUND-FILL)
    (make-aqua-selection img width)
    (gimp-selection-invert img)
    (gimp-edit-clear maskombre)

    (gimp-selection-none img)
    (gimp-context-set-foreground '(0 0 0))
    (gimp-edit-fill lum FOREGROUND-FILL)
    (make-aqua-selection img width)
    (gimp-selection-shrink img 30)
    (gimp-selection-translate img 0 45)
    (gimp-context-set-foreground '(255 255 255))
    (gimp-edit-fill lum FOREGROUND-FILL)
    (gimp-selection-none img)
    (plug-in-gauss-rle2 1 img lum 50 50)

    (gimp-rect-select img 122 50 (- width 244) 40 2 0 0)
    (set! chacha (car (gimp-selection-save img)))
    (gimp-selection-none img)
    (plug-in-gauss-iir 1 img chacha 36 1 1)
    (gimp-levels chacha HISTOGRAM-VALUE 123 133 1.0 0 255)
    (gimp-selection-load chacha)
    (gimp-image-remove-channel img chacha)
    (gimp-context-set-foreground '(0 0 0))
    (gimp-edit-blend reflh 	FG-BG-HSV-MODE
		     		NORMAL-MODE
				GRADIENT-LINEAR
				100
				0
				REPEAT-NONE
				FALSE
				FALSE
				0 0
				FALSE
				256 97
				256 50)
;    (gimp-perspective reflh 	0		; interpolation
;		      		122		; x0
;				50		; y0
;				(- width 122)	; x1 122+268
;				50		; y1
;				80		; x2
;				90		; y2
;				(- width 80)	; x3 122+268+42
;				90)		; y3
    (gimp-drawable-transform-perspective-default
                                reflh
                                122		; x0
				50		; y0
				(- width 122)	; x1 122+268
				50		; y1
				80		; x2
				90		; y2
				(- width 80)	; x3 122+268+42
				90		; y3
                                0               ; interpolation
                                0)              ; cliping
    (set! floflo (car (gimp-image-get-floating-sel img)))
    (gimp-floating-sel-anchor floflo)

    (gimp-ellipse-select img 40 40 176 176 2 TRUE 0 0)
    (gimp-ellipse-select img 55 20 216 216 1 TRUE 1 32)
    (gimp-ellipse-select img (- width 216) 40 176 176 0 TRUE 0 0)
    (gimp-ellipse-select img (- width 271) 20 216 216 1 TRUE 1 32)
    
    (gimp-edit-fill cote FOREGROUND-FILL)
    (gimp-selection-none img)

    (gimp-context-pop)
    ))


(define (script-fu-aqua-button		coulfg
					coulbg
					dawidth)

  (let* ((img (car (gimp-image-new dawidth 318 RGB)))
	 )
    (gimp-message-set-handler 1)
    (gimp-image-undo-disable img)
    (apply-aqua-logo-effect img coulfg coulbg dawidth)
    (gimp-image-undo-enable img)
    (gimp-display-new img)
    ))


(script-fu-register	"script-fu-aqua-button"
			"Aqua-style button"
			"This script creates a multi-layered aqua button"
			"Denis Bodor <lefinnois@lefinnois.net>"
			"Denis Bodor"
			"05/08/2005"
			""
			SF-COLOR "Button color"	'(71 124 183)
			SF-COLOR "Background"	'(255 255 255)
			SF-VALUE "width"	"512")

(script-fu-menu-register "script-fu-aqua-button"
			 "<Toolbox>/Xtns/Script-Fu/Buttons")



