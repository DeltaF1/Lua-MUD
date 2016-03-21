--[[
@Title:		Soundex Calculator
@Author:	Mike Tate
@Version:	2.0
@LastUpdated:	July 2012
@Description:	Function to Convert any Name to Soundex as per http://en.wikipedia.org/wiki/Soundex
		and http://creativyst.com/Doc/Articles/SoundEx1/SoundEx1.htm#SoundExAndCensus
]]
 
TblSoundex = {}					-- Soundex dictionary cache of previously coded Names
 
local TblCodeNum = {					-- Soundex code number table is faster as Global than Local
	A=0,E=0,I=0,O=0,U=0,Y=0,		-- H=0,W=0,	-- H & W are ignored
	B=1,F=1,P=1,V=1,
	C=2,G=2,J=2,K=2,Q=2,S=2,X=2,Z=2,
	D=3,T=3,
	L=4,
	M=5,N=5,
	R=6
	}
 
return function StrSoundex(strAnyName)
	strAnyName = string.upper(strAnyName:gsub("[^%a]",""))			-- Make name upper case letters only
	if strAnyName == "" then return "Z000" end
	local strSoundex = TblSoundex[strAnyName]				-- If already coded in cache then return previous Soundex code
	if strSoundex then return strSoundex end
	local strSoundex = string.sub(strAnyName,1,1)				-- Soundex starts with initial letter
	local tblCodeNum = TblCodeNum						-- Local reference to Global table is faster
	local strLastNum = tblCodeNum[strSoundex]				-- Set initial Soundex code number
	for i = 2, string.len(strAnyName) do
		local strCodeNum = tblCodeNum[string.sub(strAnyName,i,i)]	-- Step through Soundex code of each subsequent letter
		if strCodeNum then
			if strCodeNum > 0 and strCodeNum ~= strLastNum then	-- Not a vowel nor same as Soundex preceeding code
				strSoundex = strSoundex..strCodeNum		-- So append Soundex code until 4 chars long
				if string.len(strSoundex) == 4 then
					TblSoundex[strAnyName] = strSoundex	-- Save code in cache for future quick lookup
					return strSoundex
				end
			end
			strLastNum = strCodeNum					-- Save as Soundex preceeding code, unless H or W
		end
	end
	strSoundex = string.sub(strSoundex.."0000",1,4)				-- Pad code with zeroes to 4 chars long
	TblSoundex[strAnyName] = strSoundex					-- Save code in cache for future quick lookup
	return strSoundex
end -- function StrSoundex