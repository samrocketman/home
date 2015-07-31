; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
;
; Duplicate the current AnimationImage
; and continue (== load the duplicate as new current frame)
;
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


(define (script-fu-gap-dup-continue image drawable)
  (let* (
        (rangefrom -1)
        (rangeto   -1)
        (ncopies    1)
        )

    ; rangefrom rangeto: value -1 refers to the current frame
    (plug-in-gap-dup RUN-NONINTERACTIVE image drawable ncopies rangefrom rangeto)
    (plug-in-gap-next RUN-NONINTERACTIVE image drawable)
    (gimp-displays-flush)
  )
)

(script-fu-register "script-fu-gap-dup-continue"
                   _"<Image>/Video/Duplicate Continue"
                    "Duplicate the current AnimationImage and load the duplicate as new current frame"
                    "Wolfgang Hofer <hof@gimp.org>"
                    "Wolfgang Hofer"
                    "2004/06/12"
                    "RGB RGBA GRAY GRAYA"
                    SF-IMAGE "Image" 0
                    SF-DRAWABLE "Drawable" 0)
