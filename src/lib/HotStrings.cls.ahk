#include <ObjCSV>

class HotStrings {
    _hsCol := {}

    __New(csvFile) {
        hsCol := this._hsCol
        If !FileExist(csvFile)
            throw "File not found"
        objCSV := ObjCSV_CSV2Collection(csvFile, "Trigger,Replacement,Category,Treated", False)
        if !objCSV
            throw "Error loading CSV File"
        for row in objCSV {
            row.Trigger := trim(row.Trigger)
            ; skip if trigger or replacement field empty
            if not (row.Trigger and row.Replacement)
                continue
            if hsCol.HasKey(row.Trigger)
                hsCol[row.Trigger].Add_Replacement(row.Replacement)
        }
    }

    __Get(key) {
        return this._hsCol[key]
    }

    __Set(key, value) {
        this._hsCol[key] := value
    }

    Where(objWhere) {

    }
}

class HotString {
    _trigger
    _replacement
    _category
    _treated

    Trigger {
        get {
            return this._trigger
        }
        set {
            this._trigger := value
        }
    }

    Add_Replacement(replacement) {
        if this._replacement and !IsObject(this._replacements)
            this._replacement := [this._replacement]
        this._replacements.Push(replacement)
    }

    Replacement {
        get {
            if IsObject(this._replacement) {
                replacement := this._replacement.Pop()
                this._replacement.InsertAt(1, replacement)
                return replacement

            }
            return this._replacement
        }
        set {
            this._replacement := value
        }
    }

    Category {
        get {
            return this._category
        }
        set {
            this._category := value
        }
    }

    Treated {
        get {
            return this._treated
        }
        set {
            this._treated := value
        }
    }
}
