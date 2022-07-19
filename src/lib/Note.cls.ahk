Class Note {
    _id :=
    _fullPath :=
    _directory :=
    _dirty := False
    _content :=

    __New(Id, fullPath, directory) {
        if !FileExist(fullPath)
            throw File does not exist
        this._Id := Id
        this._fullPath := fullPath
        this._directory := directory
    }

    Id {
        get {
            return this._id
        }
    }

    FileName {
        get {
            fullPath := this._fullPath
            SplitPath fullPath,,,,fileName
            return fileName
        }
    }

    FullPath {
        get {
            return this._fullPath
        }
    }

    Directory {
        get {
            return this._directory
        }
        set {
            if value not in 0,1
                throw "Value must be boolean"
            this._directory := value
        }
    }

    Dirty {
        get {
            return this._dirty
        }
        set {
            if value not in 0,1
                Throw "Value must be boolean"
            this._dirty := value
            Gui, Picker:+LastFound
            Gui, Treeview, PICKER_TVNOTES
            noteId := this._id
            if !value {
                TV_Modify(noteId, "-Bold")
                GuiControl, Disable, PICKER_BTNSAVE
            } else {
                TV_Modify(noteId, "+Bold")
                GuiControl, Enable, PICKER_BTNSAVE
            }
        }
    }

    Content {
        get {
            return this._content
        }
        set {
            this._content := value
        }
    }
}