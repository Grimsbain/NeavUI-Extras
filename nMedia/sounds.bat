@echo off
echo local path = "Interface\\AddOns\\nMedia\\sounds\\"
echo local LSM = LibStub("LibSharedMedia-3.0", true)
echo if not LSM then return end
for /F "delims==" %%G in ('dir /b sounds') do echo LSM:Register("sound", "%%~nG", path.."%%G")
