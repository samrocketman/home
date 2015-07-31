;
; Smart Sharpening, Redux, V2.1
;
; Martin Egger (martin.egger@gmx.net)
; (C) 2005, Bern, Switzerland
;
; You can find more about Smart Sharpening at
; http://www.gimpguru.org/Tutorials/SmartSharpening2/
;
; This plugin was tested with Gimp 2.2
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
; Define the function
;
(define (script-fu-Eg-SmartSharpen InImage InLayer InRadius InAmount InThreshold InEdge InBlur InFlatten)
;
; Save history			
;
	(gimp-image-undo-group-start InImage)
;
	(let*	(
		(MaskImage (car (gimp-image-duplicate InImage)))
		(MaskLayer (cadr (gimp-image-get-layers MaskImage)))
;
		(OrigLayer (cadr (gimp-image-get-layers InImage)))
		(HSVImage (car (plug-in-decompose TRUE InImage InLayer "Value" TRUE)))
   		(HSVLayer (cadr (gimp-image-get-layers HSVImage)))
;
		(SharpenLayer (car (gimp-layer-copy InLayer TRUE)))
		)
;
		(gimp-image-add-layer InImage SharpenLayer -1)
;
  		(gimp-selection-all HSVImage)
   		(gimp-edit-copy (aref HSVLayer 0))
   		(gimp-image-delete HSVImage)
  		(gimp-floating-sel-anchor (car (gimp-edit-paste SharpenLayer FALSE)))
;
   		(gimp-layer-set-mode SharpenLayer VALUE-MODE)
;
; Find edges, Warpmode = Smear (1), Edgemode = Sobel (0)
;
		(plug-in-edge TRUE MaskImage (aref MaskLayer 0) InEdge 1 0)
		(gimp-levels-auto (aref MaskLayer 0))
		(gimp-convert-grayscale MaskImage)
		(plug-in-gauss TRUE MaskImage (aref MaskLayer 0) InBlur InBlur 0)
;
		(let*	(
			(SharpenChannel (car (gimp-layer-create-mask SharpenLayer ADD-WHITE-MASK)))
			)
			(gimp-layer-add-mask SharpenLayer SharpenChannel)
;
			(gimp-selection-all MaskImage)
			(gimp-edit-copy (aref MaskLayer 0))
			(gimp-floating-sel-anchor (car (gimp-edit-paste SharpenChannel FALSE)))
			(gimp-image-delete MaskImage)
;
			(plug-in-unsharp-mask TRUE InImage SharpenLayer InRadius InAmount InThreshold)
			(gimp-layer-set-opacity SharpenLayer 80)
		)
;
; Flatten the image, if we need to
;
		(cond
			((= InFlatten TRUE) (gimp-image-merge-down InImage SharpenLayer CLIP-TO-IMAGE))
			((= InFlatten FALSE) (gimp-drawable-set-name SharpenLayer "Sharpened"))
		)
	)
;
; Finish work
;
	(gimp-image-undo-group-end InImage)
	(gimp-displays-flush)
;
)
;
(script-fu-register 
	"script-fu-Eg-SmartSharpen"
	"<Image>/Script-Fu/Eg/Sharpen (Smart Redux)"
	"Smart Sharpening, Redux version"
	"Martin Egger (martin.egger@gmx.net)"
	"2005, Martin Egger, Bern, Switzerland"
	"14.06.2005"
	"RGB* GRAY*"
	SF-IMAGE	"The Image"		0
	SF-DRAWABLE	"The Layer"		0
	SF-ADJUSTMENT	"Radius of USM"		'(2.0 0.0 50.0 1 0 2 0)
	SF-ADJUSTMENT	"Amount of USM"		'(1.0 0.0 5.0 0.5 0 2 0)
	SF-ADJUSTMENT	"Threshold"		'(0.0 0.0 50.0 1.0 0 2 0)
	SF-ADJUSTMENT	"Edges: Detect Amount"	'(6.0 1.0 10.0 1.0 0 2 0)
	SF-ADJUSTMENT	"Edges: Blur Pixels"	'(6.0 1.0 10.0 1.0 0 2 0)
	SF-TOGGLE	"Flatten Image"		FALSE
)
;