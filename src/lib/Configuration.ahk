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
                IniRead, csvFile, %configFile%, Configuration, CsvFile
                if (csvFile == "ERROR") {
                    FileSelectFile, fsfValue, 3
                    ,, Choose your HotStrings CSV file, CSV File (*.csv)
                    if (fsfValue) {
                        IniWrite, %fsfValue%, %configFile%
                        , Configuration, CsvFile
                        csvFile := fsfValue
                    } else {
                        OutputDebug, % "Must have a CSV File"
                        MsgBox, 16, HotStrings.ahk - No CSV File
                        , Must have a CSV File
                        ExitApp, 1
                    }
                }
                this._csvFile := csvFile
            }
            return this._csvFile
        }
        set {
            configFile := this._configFile
            if (SubStr(value, -4) = ".csv" ) {
                if InStr(FileExist(value), "N") {
                    IniWrite, %value%, %configFile%, Configuration, CsvFile
                    this._csvFile := value
                } else {
                    throw "CSV File must exist"
                }
            } else {
                throw "File must be a CSV"
            }
        }
    }

    document {
        get {
            configFile := this._configFile
            if (!this._document) {
                IniRead, document, %configFile%, Configuration, Document
                if (document == "ERROR") {
                    FileSelectFile, document, 3, %A_MyDocuments%
                    , Choose your document, Document (*.*)
                    if (document) {
                        IniWrite, %document%, %configFile%
                        , Configuration, Document
                    }
                }
                this._document := document
            }
            return this._document
        }
        set {
            configFile := this._configFile
            if InStr(FileExist(value), "N") {
                IniWrite, %value%, %configFile%, Configuration, Document
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
                IniRead, defaultCategory, %configFile%
                , Configuration, DefaultCategory
                if (defaultCategory == "ERROR") {
                    IniWrite, %NULL%, %configFile%
                    , Configuration, DefaultCategory
                    defaultCategory :=
                }
                this._defaultCategory := defaultCategory
            }
            return this._defaultCategory

        }
        set {
            configFile := this._configFile
            IniWrite, value, %configFile%
            , Configuration, DefaultCategory
            this._defaultCategory := value
        }
    }

    stickyDefault {
        get {
            configFile := this._configFile
            if !this._stickyDefault {
                IniRead, stickyDefault, %configFile%
                , Configuration, StickyDefault
                if (stickyDefault == "ERROR") {
                    stickyDefault := true
                    IniWrite, %stickyDefault%, %configFile%
                    , Configuration, StickyDefault
                }
                this._stickyDefault := stickyDefault
            }
            return this._stickyDefault
        }
        set {
            configFile := this._configFile
            value := value?true:false
            IniWrite, %value%, %configFile%
            , Configuration, StickyDefault
            this._stickyDefault := value
        }
    }
}
