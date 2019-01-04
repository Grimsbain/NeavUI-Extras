@echo off
echo local path = "Interface\\AddOns\\nMedia\\fonts\\"
echo local LSM = LibStub("LibSharedMedia-3.0", true)
echo if not LSM then return end
for /F "delims==" %%G in ('dir /b fonts') do echo LSM:Register("font", "%%~nG", path.."%%G")
