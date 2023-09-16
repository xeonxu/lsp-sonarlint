;;; lsp-sonarlint.el --- Emacs SonarLint lsp client              -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Fermin Munoz

;; Author: Fermin MF <fmfs@posteo.net>
;; Created: 13 Jun 2020
;; Version: 0.0.1
;; Keywords: languages, tools, php, javascript, typescript, go, xml, html, java, python
;; URL: https://github.com/emacs-lsp/lsp-sonarlint
;; Package-Requires: ((emacs "27.1") (dash "2.12.0") (lsp-mode "6.3") (ht "2.3"))
;; License: GPL-3.0-or-later

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
;; SonarLint LSP extensions for GNU Emacs, add support for the majority of sonarlint languages
;; including: php, javascript, typescript, html, python and java.

;; This is NOT an official SonarLint extension.


;;; Code:

(require 'lsp-mode)
(require 'dash)
(require 'cus-edit)
(require 'ht)
(require 'shr)

(defgroup lsp-sonarlint nil
  "SonarLint lsp server group"
  :group 'lsp-mode
  :link '(url-link "https://github.com/emacs-lsp/lsp-sonarlint")
  :package-version '(lsp-mode . "6.4"))

(defcustom lsp-sonarlint-cfamily-enabled t
  "Enable lsp-sonarlint-cfamily plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-go-enabled t
  "Enable lsp-sonarlint-go plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-html-enabled t
  "Enable lsp-sonarlint-html plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-java-enabled t
  "Enable lsp-sonarlint-java plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-javascript-enabled t
  "Enable lsp-sonarlint-javascript plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-php-enabled t
  "Enable lsp-sonarlint-php plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-python-enabled t
  "Enable lsp-sonarlint-python plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-text-enabled t
  "Enable lsp-sonarlint-text plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-typescript-enabled t
  "Enable lsp-sonarlint-typescript plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-xml-enabled t
  "Enable lsp-sonarlint-xml plugin."
  :group 'lsp-sonarlint
  :type 'boolean)

(defun lsp-sonarlint-modes-enabled ()
  "Get mode list which sonarlint should active."
  (-mapcat (lambda (mode-dict)
             (let ((mode-enabled (eval (car mode-dict))))
               (when mode-enabled
                 (cdr mode-dict) )))
           '((lsp-sonarlint-cfamily-enabled . ("c" "cpp" "objective-c" "cuda"))
             (lsp-sonarlint-go-enabled . ("go"))
             (lsp-sonarlint-html-enabled . ("html"))
             (lsp-sonarlint-java-enabled . ("java"))
             (lsp-sonarlint-javascript-enabled . ("js"))
             (lsp-sonarlint-php-enabled . ("php"))
             (lsp-sonarlint-python-enabled . ("python"))
             (lsp-sonarlint-text-enabled . ("text"))
             (lsp-sonarlint-typescript-enabled . ("typescript"))
             (lsp-sonarlint-xml-enabled . ("xml")))))

;; (let* ((lsp-sonarlint--enabled-plugins
;;         (-filter (lambda (member)
;;        	           (when (eval
;;        		          (intern (concat (format "%s" (car member) ) "-enabled")))
;;        	             t))
;;        	         (custom-group-members 'lsp-sonarlint t))))
;;   (lsp-sonarlint--remove-duplicate-plugins
;;    (-map (lambda (enabled-member)
;;            (let* ((enabled-member--download-url
;;                    (eval (intern (concat (format "%s" (car enabled-member) ) "-download-url"))))
;;                   (enabled-member--analyzer-path
;;                    (eval (intern (concat (format "%s" (car enabled-member) ) "-analyzer-path")))))
;;              (unless (file-exists-p
;;                       enabled-member--analyzer-path)
;;                (when (or lsp-sonarlint-plugin-autodownload
;;                          (yes-or-no-p
;;                           (format "sonarlint language server plugin not found, do you want to download it? ")))
;;                  (url-copy-file lsp-sonarlint-vscode-plugin-url enabled-member--analyzer-path)))
;;              enabled-member--analyzer-path))
;;          lsp-sonarlint--enabled-plugins)))

;; (defcustom lsp-sonarlint-modes-enabled '(
;;                                          ;; Cfamilies
;;                                          "c"
;;                                          "cpp"
;;                                          "objective-c"
;;                                          "cuda"
;;                                          ;; php
;;                                          "php"
;;                                          ;; go
;;                                          "go"
;;                                          ;; web
;;                                          "html"
;;                                          ;; javascript
;;                                          "js"
;;                                          "typescript"
;;                                          ;; python
;;                                          "python"
;;                                          ;; java
;;                                          "java"
;;                                          ;; xml
;;                                          "xml"
;;                                          )
;;   "List of major modes that enable SonarLint backend for LSP mode."
;;   :group 'lsp-sonarlint
;;   :type 'file)

(defcustom lsp-sonarlint-disable-telemetry t
  "Disable sending anonymous usage statistics to SonarSource.
To see a sample of the data that are collected
https://github.com/SonarSource/sonarlint-vscode/blob/master/telemetry-sample.md."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-test-file-pattern "{**/test/**,**/*test*,**/*Test*}"
  "Files whose name match java global are considered as test files by analyzers.
Most rules are not evaluated on test files.
Example: `{**/test/**,**/*test*,**/*Test*}`"
  :group 'lsp-sonarlint
  :type 'string)

(defcustom lsp-sonarlint-show-analyzer-logs nil
  "Show analyzer's logs in the SonarLint output."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-verbose-logs nil
  "Enable verbose logging of the SonarLint language server."
  :group 'lsp-sonarlint
  :type 'boolean)

(defcustom lsp-sonarlint-vmargs ""
  "Extra JVM arguments used to launch the SonarLint LSP.
e.g. `-Xmx1024m`."
  :group 'lsp-sonarlint
  :type 'string)

(lsp-defcustom lsp-sonarlint--compilecommands-path-property ""
  "Property of compilecommands path."
  :group 'lsp-sonarlint
  :lsp-path "sonarlint.pathToCompileCommands")

(defconst lsp-sonarlint-vscode-plugin-version-hash-tbl
  '(("3.21.0" . "%2B74430")
    ("3.20.2" . "%2B74272"))
  "Alist of vscode plugin and commit hash.")

(defcustom lsp-sonarlint-vscode-plugin-version
  "3.21.0"
  "Specify the version of SonarLint VSCode Plugin."
  :group 'lsp-sonarlint
  :type 'string)

(defcustom lsp-sonarlint-vscode-plugin-url
  (let ((vscode-plugin-version-table (assoc lsp-sonarlint-vscode-plugin-version lsp-sonarlint-vscode-plugin-version-hash-tbl)))
    (when (null vscode-plugin-version-table)
      ;; Set default value
      (setq vscode-plugin-version-table '("3.21.0" . "%2B74430")))
    (let ((vscode-plugin-version (car vscode-plugin-version-table))
          (vscode-plugin-hash (cdr vscode-plugin-version-table)))
      (concat "https://github.com/SonarSource/sonarlint-vscode/releases/download/" vscode-plugin-version vscode-plugin-hash  "/sonarlint-vscode-" vscode-plugin-version ".vsix")))
  "SonarLint VSCode Plugin VISX file download URL."
  :group 'lsp-sonarlint
  :type 'string)

(defcustom lsp-sonarlint-vscode-plugin-store-path
  (file-name-concat user-emacs-directory "sonarlint" "download/")
  "SonarLint VSCode Plugin VISX file store path."
  :group 'lsp-sonarlint
  :type 'string)

(defcustom lsp-sonarlint-vscode-plugin-extract-path
  (file-name-concat user-emacs-directory "sonarlint" "extract/")
  "SonarLint VSCode Plugin VISX file extract path."
  :group 'lsp-sonarlint
  :type 'string)

(defcustom lsp-sonarlint-server-path (let ((server-path (concat lsp-sonarlint-vscode-plugin-extract-path "extension/server/")))
                                       (if (file-exists-p server-path)
                                           (car (directory-files (concat lsp-sonarlint-vscode-plugin-extract-path "extension/server/") t ".*\.jar"))
                                         nil))
  "SonarLint Language Server jar file location."
  :group 'lsp-sonarlint
  :type 'file)

(defcustom lsp-sonarlint-plugin-autodownload nil
  "Whether to go ahead and download missing plugins not asking for a confirmation.
Useful for batch testing."
  :group 'lsp-sonarlint
  :type 'boolean)

;; (let ((languages-directory-path (concat (file-name-directory load-file-name) "languages")))
;;   (if (file-directory-p languages-directory-path)
;;       (add-to-list 'load-path languages-directory-path)
;;     (error "There was an error with the `load-file-name` function")))

(defun lsp-sonarlint--remove-duplicate-plugins (jars)
  "Return copy of JARS with duplicates removed.
The duplicates may occur if the same plugin implements different languages,
for example sonar-javascript.jar covers both JavaScript and TypeScript.
If a duplicate occurs, SonarLint will throw an exception."
  (cl-remove-duplicates jars :test #'equal :key (lambda (jar-path) (file-name-base jar-path))))

(defun lsp-sonarlint--download-plugins ()
  "Check if sonarlint vscode plugin exists. If not, download it from web.
And extract it to `lsp-sonarlint-vscode-plugin-extract-path` specified path."
  (let* ((vscode-plugin--file-name (file-name-with-extension (file-name-base lsp-sonarlint-vscode-plugin-url) (file-name-extension lsp-sonarlint-vscode-plugin-url)))
         (vscode-plugin--store-file-path (concat lsp-sonarlint-vscode-plugin-store-path vscode-plugin--file-name)))
    (unless (file-exists-p lsp-sonarlint-vscode-plugin-store-path)
      (mkdir lsp-sonarlint-vscode-plugin-store-path t))
    (unless (file-exists-p vscode-plugin--store-file-path)
      (when (or lsp-sonarlint-plugin-autodownload
                (yes-or-no-p
                 (format "Sonarlint language server plugin not found, do you want to download it? ")))
        (url-copy-file lsp-sonarlint-vscode-plugin-url vscode-plugin--store-file-path)))
    (when (file-exists-p lsp-sonarlint-vscode-plugin-extract-path)
      (delete-directory lsp-sonarlint-vscode-plugin-extract-path t))
    (unless (file-exists-p lsp-sonarlint-vscode-plugin-extract-path)
      (mkdir lsp-sonarlint-vscode-plugin-extract-path t))
    (lsp-unzip vscode-plugin--store-file-path lsp-sonarlint-vscode-plugin-extract-path)))

(defun lsp-sonarlint--plugin-list ()
  "Check for the enabled extensions and return a path list.
If the analyzer path is not a file, and
lsp-sonarlint-plugin-autodownload is not nil it offers to
download the analyzer, and does that."
  (let* ((lsp-sonarlint--analyzers-list (directory-files (concat lsp-sonarlint-vscode-plugin-extract-path "extension/analyzers/") t ".*\.jar")))
    lsp-sonarlint--analyzers-list
    ))

(defun lsp-sonarlint--code-action-open-rule (_workspace params)
  "Create a buffer with rendered rule from PARAMS text in it.
Extracts the title ahd htmlDescription, and renders the HTML in a
temporary buffer."
  (with-temp-buffer
    (let* ((rule-title (format "<h1>%s</h1><hr/>" (ht-get params "name")))
           (rule-body (ht-get params "htmlDescription")))
      (insert rule-title)
       (insert "\n")
       (insert rule-body))
    (shr-render-buffer (current-buffer))))


(defun lsp-sonarlint-server-start-fun (port)
  "Start lsp-sonarlint in TCP mode listening to port PORT."
  (when (eq lsp-sonarlint-server-path nil)
    (if (equal (lsp-sonarlint--download-plugins) 0)
        (setq lsp-sonarlint-server-path (car (directory-files (concat lsp-sonarlint-vscode-plugin-extract-path "extension/server/") t ".*\.jar")))))
  (-concat
   `("java" "-jar" ,(eval lsp-sonarlint-server-path)  ,(format "-port=%d" port))
   '("-analyzers") (mapcar (lambda (plugin-path) (format "%s" plugin-path))
			    (lsp-sonarlint--plugin-list))))

(defconst lsp-sonarlint--action-handlers '())

(lsp-register-custom-settings
 '(("sonarlint.disableTelemetry" lsp-sonarlint-disable-telemetry)
   ("sonarlint.testFilePattern" lsp-sonarlint-test-file-pattern)
   ("sonarlint.output.showAnalyzerLogs" lsp-sonarlint-show-analyzer-logs)
   ("sonarlint.output.verboseLogs" lsp-sonarlint-verbose-logs)
   ("sonarlint.ls.vmargs" lsp-sonarlint-vmargs)
   ;; ("sonarlint.pathToCompileCommands" (lambda () (lsp-sonarlint--get-compilecommands-path)))
   ))

(defun lsp-sonarlint--request-handlers ()
  "SonarLint-specific request handlers.
See REQUEST-HANDLERS in lsp--client in lsp-mode."
  (let ((ht (make-hash-table :test 'equal)))
    ;; Check whether the file is just being previewed or is actually open in an editor
    ;; to save some wasted work.
    ;; I guess it is safe to assume, when lsp-mode sends a file over to the server,
    ;; it is because it is open in editor.
    (puthash "sonarlint/isOpenInEditor" (lambda (_workspace _params) t) ht)
    ;; Check if the file is ignored by Source Control Manager (a.k.e. VCS, version control system).
    ;; I think this is related to .gitignore and similar files.
    ;; Probably safe to assume as a first step that you don't care, and want your diagnostics.
    ;; TODO: implement a proper check here.
    (puthash "sonarlint/isIgnoredByScm" (lambda (_workspace _params) nil) ht)
    ;; Get the VCS branch name. Let it be nil for now
    ;; TODO: implement a proper response
    (puthash "sonarlint/getBranchNameForFolder" (lambda (_workspace _params) nil) ht)
    ;; Probably only relevant to the java analyzer.
    ;; Some additional java configuration for the project.
    ;; TODO: implement
    (puthash "sonarlint/getJavaConfig" (lambda (_workspace _params) nil) ht)
    ht))

(defun lsp-sonarlint--get-compilecommands-path (&optional current-dir)
  "Return the first found path of compile_commands.json file from current directory up to parent directories."
  (unless current-dir
    (setq current-dir default-directory))
  (let* ((target-file (file-name-concat current-dir "compile_commands.json"))
         (parent-dir (file-name-parent-directory current-dir)))
    (if (and (file-exists-p current-dir)
             (not (file-exists-p target-file)))
        (if parent-dir
            (lsp-sonarlint--get-compilecommands-path parent-dir)
          (concat (lsp--suggest-project-root) "compile_commands.json"))
      target-file)))

(defun lsp-sonarlint--notification-handlers ()
  "SonarLint-specific notification handlers.
See NOTIFICATION-HANDLERS in lsp--client in lsp-mode."
  (let ((ht (make-hash-table :test 'equal)))
    ;; Security Hotspots are a special kind of issue that have particular
    ;; interface on SonarCloud, SonarQube, and in SonarLint. See
    ;; https://docs.sonarcloud.io/digging-deeper/security-hotspots/ I presume
    ;; the PARAMS contain a list of issues of this category, similar to the
    ;; normal issues.
    ;; TODO: display them, perhaps optionally, as they could be noisy sometimes,
    ;; especially without the possibility to "review" them once and forever.
    (puthash "sonarlint/publishSecurityHotspots" (lambda (_workspace _params) nil) ht)
    ;; Not sure what this is for. Testing of SonarLint itself?
    (puthash "sonarlint/readyForTests" (lambda (_workspace _params) nil) ht)
    ;; This is probably just to raise awareness of the new kind of issues:
    ;; secrets. That'd be too booring to implement. Hopefully, the user is
    ;; paying attention and will notice anyway.
    (puthash "sonarlint/showNotificationForFirstSecretsIssue" (lambda (_workspace _params) nil) ht)
    (puthash "sonarlint/showRuleDescription" #'lsp-sonarlint--code-action-open-rule ht)
    ;; (puthash "workspace/didChangeWorkspaceFolders" (lambda (_workspace _params)
    ;;                                                  (with-lsp-workspace _workspace
    ;;                                                  (message "3#########%s" (ht-get (ht-get (lsp-configuration-section "sonarlint") "sonarlint") "pathToCompileCommands"))
    ;;                                                  (setq lsp-sonarlint--compilecommands-path-property (lambda () (lsp-sonarlint--get-compilecommands-path)))
    ;;                                                  (lsp--set-configuration (lsp-configuration-section "sonarlint"))
    ;;                                                  ;; (lsp--set-configuration (lsp-configuration-section "sonarlint"))
    ;;                                                  ;; (lsp-register-custom-settings
    ;;                                                  ;;  `(("pathToCompileCommands" ,(lsp-sonarlint--get-compilecommands-path))))
                                                     
    ;;                                                  (message "4#########%s" (ht-get (ht-get (lsp-configuration-section "sonarlint") "sonarlint") "pathToCompileCommands")))) ht)
    ;; TODO
    (puthash "sonarlint/needCompilationDatabase" (lambda (_workspace _params)
                                                   (message "Try to set sonarlint.pathToCompileCommands to \"%s\"" (lsp-sonarlint--get-compilecommands-path))
                                                   ;; (lsp--set-custom-property
                                                   ;;  'pathToCompileCommands (lsp-sonarlint--get-compilecommands-path) "pathToCompileCommands")
                                                   (with-lsp-workspace _workspace
                                                     (message "1#########%s" (ht-get (ht-get (lsp-configuration-section "sonarlint") "sonarlint") "pathToCompileCommands"))
                                                     (setq lsp-sonarlint--compilecommands-path-property (lsp-sonarlint--get-compilecommands-path))
                                                     (lsp--set-configuration (lsp-configuration-section "sonarlint"))
                                                     ;; (lsp--set-configuration (lsp-configuration-section "sonarlint"))
                                                     ;; (lsp-register-custom-settings
                                                     ;;  `(("pathToCompileCommands" ,(lsp-sonarlint--get-compilecommands-path))))
                                                     
                                                     (message "2#########%s" (ht-get (ht-get (lsp-configuration-section "sonarlint") "sonarlint") "pathToCompileCommands")))
                                                   (add-hook 'window-state-change-hook 'lsp-sonarlint--window-change-hook)

                                                   ) ht) ht))

;; (advice-add 'lsp :before (lambda (&rest _args) (eval '(setf (lsp-session-server-id->folders (lsp-session)) (ht)))))
(defvar lsp-sonarlint--old-compilecommands-path-property "")

(defun lsp-sonarlint--window-change-hook ()
  "Hook while window has changed."
  ;; Return if buffer without filename
  (when (and (buffer-file-name)
             lsp-mode
             c-buffer-is-cc-mode)
    (setq lsp-sonarlint--compilecommands-path-property (lsp-sonarlint--get-compilecommands-path))
    (when (not (equal lsp-sonarlint--compilecommands-path-property
                      lsp-sonarlint--old-compilecommands-path-property))
      (with-lsp-workspace (lsp-find-workspace 'sonarlint (buffer-file-name))
        (lsp--set-configuration (lsp-configuration-section "sonarlint"))
        (setq lsp-sonarlint--old-compilecommands-path-property lsp-sonarlint--compilecommands-path-property)
        (message "Change compilation database to %s" lsp-sonarlint--compilecommands-path-property)))))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-tcp-server-command 'lsp-sonarlint-server-start-fun)
  :activation-fn (lambda (_file-name _mode)
    (-contains? (lsp-sonarlint-modes-enabled) (lsp-buffer-language)))
  :priority -1
  :request-handlers (lsp-sonarlint--request-handlers)
  :notification-handlers (lsp-sonarlint--notification-handlers)
  :add-on? t
  :multi-root t
  :server-id 'sonarlint
  :action-handlers (ht<-alist lsp-sonarlint--action-handlers)
  :initialization-options (lambda ()
			    (list
			     :productKey "emacs"
			     :productName "Emacs"))
  :initialized-fn (lambda (workspace)
                    (with-lsp-workspace workspace
                      (setq lsp-sonarlint--old-compilecommands-path-property lsp-sonarlint--compilecommands-path-property)
                      (lsp--set-configuration
                       (lsp-configuration-section "sonarlint"))))))

(provide 'lsp-sonarlint)
;;; lsp-sonarlint.el ends here
