Stop = 'Stop'
 = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjQzQjM1MkE1MzExQkM4REJDNTIzRjdERUNGRkU1RTJDNUQxMkIxQTciLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjkxMDY2MDk3LTI2MjYtNDU3Yy1hMTAxLTU0ZTU4NGEzNzdhOSIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy11cy1yMS53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLXVzLXIxLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiNGY5M2UxOTctNGE5YS00MmIzLThkNWYtNGZkNTM0YWU2NTk0IiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJVUyIsIkdsb2JhbEJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovLzRmOTNlMTk3LTRhOWEtNDJiMy04ZDVmLTRmZDUzNGFlNjU5NC5yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJCcm9rZXJSZXNvdXJjZUlkVXJpIjoiaHR0cHM6Ly80ZjkzZTE5Ny00YTlhLTQyYjMtOGQ1Zi00ZmQ1MzRhZTY1OTQucmRicm9rZXItZy11cy1yMS53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1Jlc291cmNlSWRVcmkiOiJodHRwczovLzRmOTNlMTk3LTRhOWEtNDJiMy04ZDVmLTRmZDUzNGFlNjU5NC5yZGRpYWdub3N0aWNzLWctdXMtcjEud3ZkLm1pY3Jvc29mdC5jb20vIiwiQUFEVGVuYW50SWQiOiJmYTg0NDNjNi01YTM5LTRkZjUtYTAxOC05Yzg3NjQ1NWFkZjkiLCJuYmYiOjE3ODY2MTc5MzUsImV4cCI6MTc4NjcwNDMzMywiaXNzIjoiUkRJbmZyYVRva2VuTWFuYWdlciIsImF1ZCI6IlJEbWkifQ.VLPeHAfk2AkScMuTt8CWagHeoMSytDz13ydpjJMr7fkmxS3GoxUD-h2YZSJEvnm1lfkMwYvb2oenjOXWcpPC7_uPxEVbkdhNTObK57SoDZUNjnMkaV9bLvOjOdUJ9KgO_Hs2ZmNTxilAHRa_QIyT59h1kyc9wqbKSFOjSfVG3cfmaP04IXBG5YNXuD4V5Yo8WpR52utrpBbcI4uCohTn_2HoiAP2e6aaZFbQw1VQ8q-a8QMiQoCXoMET55ZdIijgPxlUXOlRz3mFYdTegYq1sNUBTnaGweMXelA7sg7BtLmdk1p-c_gs_M3bT2WtJTxczMhpGLyFMgl2FfpI5q4I-g'
 = @(
  'https://go.microsoft.com/fwlink/?linkid=2310011',
  'https://go.microsoft.com/fwlink/?linkid=2311028'
)
 = @()
foreach ( in ) {
   = Invoke-WebRequest -MaximumRedirection 0 -Uri  -ErrorAction SilentlyContinue -UseBasicParsing
   = .Headers.Location
   = Split-Path  -Leaf
  Invoke-WebRequest -Uri  -UseBasicParsing -OutFile 
  Unblock-File -Path 
   += (Join-Path C:\Users\labuser\Documents\Training )
}
 =  | Where-Object {  -like '*RDAgent.Installer*' }
 =  | Where-Object {  -like '*RDAgentBootLoader.Installer*' }
Start-Process msiexec.exe -ArgumentList @('/i', , '/quiet', 'REGISTRATIONTOKEN=' + ) -Wait -NoNewWindow
Start-Process msiexec.exe -ArgumentList @('/i', , '/quiet') -Wait -NoNewWindow
Get-Service -Name RDAgent,BootLoader -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType
