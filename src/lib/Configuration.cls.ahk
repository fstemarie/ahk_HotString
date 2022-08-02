Class Configuration {
    __New(configFile) {
        if !FileExist(configFile) {
            throw "INI File not found"
        }
        this._configFile := configFile
    }

    csvFile {
        get {
            configFile := this._configFile
            if !this._csvFile {
                IniRead, csvFile, %configFile%, Configuration, csvFile
                if (csvFile == "ERROR") {
                    IniWrite, %NULL%, %configFile%, Configuration, csvFile
                    csvFile :=
                }
                this._csvFile := csvFile
            }
            return this._csvFile
        }
        set {
            configFile := this._configFile
            test := SubStr(value, -3)
            if (SubStr(value, -3) = ".csv" ) {
                if FileExist(value) {
                    IniWrite, %value%, %configFile%, Configuration, csvFile
                    this._csvFile := value
                } else {
                    throw "CSV File must exist"
                }
            } else {
                throw "File must be a CSV"
            }
        }
    }

    notesDir {
        get {
            configFile := this._configFile
            if !this._notesDir {
                IniRead, notesDir, %configFile%, Configuration, notesDir
                if (notesDir == "ERROR") {
                    IniWrite, %NULL%, %configFile%, Configuration, notesDir
                    notesDir :=
                }
                this._notesDir := notesDir
            }
            return this._notesDir

        }
        set {
            configFile := this._configFile
            if InStr(FileExist(value), "D") {
                IniWrite, %value%, %configFile%, Configuration, notesDir
                this._notesDir := value
            } else {
                throw "Notes folder must exist"
            }
        }
    }

    document {
        get {
            configFile := this._configFile
            if (!this._document) {
                IniRead, document, %configFile%, Configuration, document
                if (document == "ERROR") {
                    FileSelectFile, document, 3, %A_MyDocuments%
                    , Choose your document, Document (*.*)
                    if (document) {
                        IniWrite, %document%, %configFile%, Configuration, document
                    }
                }
                this._document := document
            }
            return this._document
        }
        set {
            configFile := this._configFile
            if InStr(FileExist(value), "N") {
                IniWrite, %value%, %configFile%, Configuration, document
                this._document := value
            } else {
                throw "Document must exist"
            }
        }
    }

    defaultCategory {
        get {
            configFile := this._configFile
            if !this._defaultCategory {
                IniRead, defaultCategory, %configFile%, Configuration, defaultCategory
                if (defaultCategory == "ERROR") {
                    IniWrite, %NULL%, %configFile%, Configuration, defaultCategory
                    defaultCategory :=
                }
                this._defaultCategory := defaultCategory
            }
            return this._defaultCategory

        }
        set {
            configFile := this._configFile
            IniWrite, %value%, %configFile%, Configuration, defaultCategory
            this._defaultCategory := value
        }
    }

    stickyDefault {
        get {
            configFile := this._configFile
            if !this._stickyDefault {
                IniRead, stickyDefault, %configFile%, Configuration, stickyDefault
                if (stickyDefault == "ERROR") {
                    stickyDefault := true
                    IniWrite, %stickyDefault%, %configFile%, Configuration, stickyDefault
                }
                this._stickyDefault := stickyDefault
            }
            return this._stickyDefault
        }
        set {
            configFile := this._configFile
            value := value?true:false
            IniWrite, %value%, %configFile%, Configuration, stickyDefault
            this._stickyDefault := value
        }
    }
}
