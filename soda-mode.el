;;; soda-mode.el -- Major mode for editing SODA files. -*- lexical-binding: t; -*-

;; Copyright (C) 2014-2019 Phil Newton <phil@sodaware.net>

;; Author: Phil Newton <phil@sodaware.net>
;; Created: 25th September, 2014
;; Version: 1.0.0

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This mode is for editing SODA files.  I'm 99% sure nobody else
;; in the universe will ever need to edit them, so it's more of a
;; learning experience for writing major modes.

;; http://www.emacswiki.org/emacs/ModeTutorial

;; Indenting
;; If at start of buffer, indent to 0
;; If on }, de-indent relative to previous line
;; if on {, increase indent

;; Auto-complete
;;   pressing ":" should bring up more complete options when not in a block
;;   definition.

;; Highlight:
;;    - // and /* */ comments
;;    - strings
;;    - [identifiers]
;;    - [n:, t:]
;;    - @ values in comments
;;    - [[ ]] values


;;; Code:

(defgroup soda-font-lock nil
  "Highlight SODA file format."
  :group 'faces)

(defvar soda-mode-hook nil)

(defvar soda-mode-map
  (let ((soda-mode-map (make-keymap)))
    (define-key soda-mode-map "\C-j" 'newline-and-indent)
    soda-mode-map)
  "Keymap for SODA major mode.")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.soda\\'" . soda-mode))

;; KEYWORDS

;; font-lock-keyword-face == blue
;; font-lock-function-name-face == yellow
;; font-lock-contant-face == green

(defconst soda-mode-font-lock-keywords-1
  (list
   '("\\<\\(t:\\|n:\\|specializes\\|doc\\|category_name\\)" . font-lock-builtin-face)
   '("\\<\\(template\\)" . font-lock-variable-name-face))
  "Minimal highlighting.")


;; (defconst soda-mode-font-lock-keywords-2
;;   (append soda-mode-font-lock-keywords-1
;;           (list
;;            '("\\<\\(equipment:\\)" . font-lock-type-face))))

;; Regular expressions
;; [a-z_:]+[\t ]+\=        <-- Get everything LEFT of the =
;; [a-z_]+:                <-- Get the class part
;; :[a-z_]+                <-- Get the variable part

(defconst soda-mode-font-lock-keywords-3
  (append soda-mode-font-lock-keywords-1
          (list
           '("\\[\\ca+\\]" . font-lock-type-face))))

(defvar soda-mode-font-lock-keywords soda-mode-font-lock-keywords-3
  "Default highlighting for SODA mode.")

(defvar soda-mode-syntax-table
  (let ((soda-mode-syntax-table (make-syntax-table)))

    ;; Make underscore part of a word
    (modify-syntax-entry ?_ "w" soda-mode-syntax-table)

    ;; Add C style comment
    (modify-syntax-entry ?/ ". 124b" soda-mode-syntax-table)
	(modify-syntax-entry ?* ". 23" soda-mode-syntax-table)
	(modify-syntax-entry ?\n "> b" soda-mode-syntax-table)
    
    soda-mode-syntax-table)
  
  "Syntax table for SODA mode.")

(defun soda-mode-syntax-propertize-function (start end)
  "Propertize between START and END."
  (let ((case-fold-search nil))

    ;; Clear all existing soda properties
    (goto-char start)
    (remove-text-properties start end '(soda-mode-interpolation))))

(defun soda-mode-syntax-propertize-interpolation ()
  "Interpolate."
  (let* ((beg (match-beginning 0))
         (context (save-excursion (save-match-data (syntax-ppss beg)))))
    (put-text-property beg (1+ beg) 'soda-mode-interpolation
                       (cons (nth 3 context) (match-data)))))

(defun soda-mode-indent-line ()
  "Indent current line as SODA code."
  (interactive)
  (beginning-of-line)

  (if (bobp)
      (indent-line-to 0) ; First line is never indented
      
      (let ((not-indented t) cur-indent)
        
        ;; If looking at the end of a block, decrease current indentation
        ;; [todo] - Should we only close a block if on a separate line?
        ;; [todo] - Likewise, should we only open a block if no closing bracked on the same line?
        (if (looking-at ".*}$")
            
            (progn
              (save-excursion
                (forward-line -1)
                (setq cur-indent (- (current-indentation) tab-width)))

              ;; [todo] - If a closing bracket, don't de-indent
              
              ;; Prevent indent from going below 0
              (when (< cur-indent 0)
                (setq cur-indent 0)))

            (save-excursion
              (while not-indented
                (forward-line -1)

                (if (looking-at ".*}$")
                    (progn
                      (setq cur-indent (current-indentation))
                      (setq not-indented nil))
                    (if (looking-at ".*{$")
                        (progn
                          (setq cur-indent (+ (current-indentation) tab-width))
                          (setq not-indented nil))
                        (if (bobp)
                            (setq not-indented nil)))))))

        (if cur-indent
            (indent-line-to cur-indent)
            (indent-line-to 0)))))

;;###autoload
(with-eval-after-load "all-the-icons"
  ;; Enable "All the icons" icons (if package is installed).
  (add-to-list
   'all-the-icons-icon-alist
   '("\\.soda$" all-the-icons-material "local_drink" :v-adjust 0.0 :face all-the-icons-lgreen))

  (add-to-list
   'all-the-icons-mode-icon-alist
   '(soda-mode all-the-icons-material "local_drink" :height 1.0 :v-adjust 0.0 :face all-the-icons-lgreen)))

;;;###autoload
(defun soda-mode ()
  "Major mode to highlight SODA files."
  (interactive)
  (kill-all-local-variables)
  (use-local-map soda-mode-map)
  
  ;; Set up highlighting
  (set-syntax-table soda-mode-syntax-table)
  (set (make-local-variable 'font-lock-defaults) '(soda-mode-font-lock-keywords))
  (set (make-local-variable 'syntax-propertize-function)
       #'soda-mode-syntax-propertize-function)
  
  ;; Set up indentation
  (set (make-local-variable 'indent-line-function) 'soda-mode-indent-line)
  (setq major-mode 'soda-mode)
  (setq mode-name "soda")
  (run-hooks 'soda-mode-hook))

(provide 'soda-mode)
;;; soda-mode.el ends here
