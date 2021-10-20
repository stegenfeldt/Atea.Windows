Describe "FileAgePB" {
    BeforeAll {
        . $PSScriptRoot/FileAgePB.ps1
    }
    

    It "Returns TGDS Video PropertyBag" {
        Get-FileAgePropertyBags -SubKeyName "TGDS Video" | Should -Not -BeNullOrEmpty
    }

}