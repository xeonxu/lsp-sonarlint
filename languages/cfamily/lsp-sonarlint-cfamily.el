;;; lsp-sonarlint-cfamily.el --- lsp-sonarlint cfamily module             -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Fermin Munoz
;; URL: https://gitlab.com/sasanidas/lsp-sonarlint
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Specific configuration for the SonarLint cfamily plugin.

;; This is NOT and official SonarLint extension.


;;; Code:

(defgroup lsp-sonarlint-cfamily nil
  "lsp-sonarlint cfamily analyzer group"
  :group 'lsp-sonarlint
  :version '(lsp-sonarlint-cfamily . "4.2.0"))

(defcustom lsp-sonarlint-cfamily-enabled nil
  "Enable lsp-sonarlint-cfamily plugin."
  :group 'lsp-sonarlint-cfamily
  :type 'boolean)

(defcustom lsp-sonarlint-cfamily-download-url
  "https://repo.maven.apache.org/maven2/org/sonarsource/cfamily/sonar-cfamily-plugin/4.2.0.11487/sonar-cfamily-plugin-4.2.0.11487.jar"
  "Cfamily plugin download URL."
  :group 'lsp-sonarlint-cfamily
  :type 'string)

(defcustom lsp-sonarlint-cfamily-analyzer-path
(concat
   (file-name-directory load-file-name)
   "sonar-cfamily.jar")
  "Lsp-sonarlint cfamily analyzer location."
  :group 'lsp-sonarlint-cfamily
  :type 'file)

(defvar lsp-sonarlint-cfamily-doc-url "https://www.sonarsource.com/c/"
  "Documentation sonarsource URL.")

(defvar lsp-sonarlint-cfamily-repository-url nil
  "Official sonarlint code extension repository.")

(provide 'lsp-sonarlint-cfamily)
;;; lsp-sonarlint-cfamily.el ends here
