; Cross Processing is a script for The GIMP
; Description: creates cross-processing-like effects on a RGB image.
; Revised version created by Marco Alici <maalici@tin.it, Copyright (C) 2005
; Revisions by Michel Bohn <bohnman@hotmail.com>,  Copyright (C) 2008
; ------------------------------------------------------------------------------------------------
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

(define (script-crossprocessing img draw red green blue)
	(print img)
	(gimp-image-undo-group-start img)
	(gimp-image-flatten img)
	(let* ( (draw (car (gimp-image-get-active-drawable img))) (points (cons-array 6 'byte)) )
		
		;(set! draw   (car (gimp-image-get-active-drawable img)))
		; creazione array di nome points con 6 elementi
		;(set! points (cons-array 6 'byte))
		; coordinate del primo punto x e y
		
		(aset points 0 0)
		(aset points 1 0)
		; coordinate del secondo punto
		(aset points 2 128)
		(aset points 3 red)
		; coordinate del terzo punto
		(aset points 4 255)
		(aset points 5 255)
		; applicazione curva su canale rosso
		(gimp-curves-spline draw 1 6 points)

		(aset points 0 0)
		(aset points 1 0)
		(aset points 2 128)
		(aset points 3 148)
		(aset points 4 255)
		(aset points 5 green)
		; applicazione curva su canale verde
		(gimp-curves-spline draw 2 6 points)

		(aset points 0 0)
		(aset points 1 0)
		; coordinate del secondo punto
		(aset points 2 128)
		(aset points 3 148)
		; coordinate del terzo punto
		(aset points 4 255)
		(aset points 5 blue)
		; applicazione curva su canale blu
		(gimp-curves-spline draw 3 6 points)
  
		; aumento del contrasto
		(let* ( (points2 (cons-array 8 'byte)) )
			;(set! points2 (cons-array 8 'byte))
			(aset points2 0 0)
			(aset points2 1 0)
			(aset points2 2 64)
			(aset points2 3 54)
			(aset points2 4 192)
			(aset points2 5 202)
			(aset points2 6 255)
			(aset points2 7 255)
			(gimp-curves-spline draw 0 8 points2)

			; ridisegno dell'immagine
			(gimp-image-undo-group-end img)
			(gimp-displays-flush)
		)
	)
)
(script-fu-register 
	"script-crossprocessing"
	"<Image>/Script-Fu/Decor/Cross Processing..."
	"creates cross-processing-like effects on a RGB image, originally written by Marco Alici <maalici@tin.it> "
	"Michel Bohn <bohnman@hotmail.com>"
	"Michel Bohn"
	"01/10/2008"
	"RGB*"
	SF-IMAGE      "Image"         0
	SF-DRAWABLE   "Drawable"      0
	SF-ADJUSTMENT "Red"           '(64 1 255 1 10 0 0)
	SF-ADJUSTMENT "Green"         '(224 1 255 1 10 0 0)
	SF-ADJUSTMENT "Blue"          '(148 1 255 1 10 0 0)
)