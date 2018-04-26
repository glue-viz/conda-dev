# We use the following function to exit the script after any failing command
function checkLastExitCode {
  if ($lastExitCode) {
    echo "ERROR: the last command returned the following exit code: $lastExitCode"
    Exit $lastExitCode
  }
}

# Show which commands are being run
Set-PSDebug -Trace 1

$env:STABLE = 'true'

$env:PYTHON_VERSION = '2.7'
& ((Split-Path $MyInvocation.InvocationName) + "\build_packages.ps1")
checkLastExitCode

$env:PYTHON_VERSION = '3.5'
& ((Split-Path $MyInvocation.InvocationName) + "\build_packages.ps1")
checkLastExitCode

$env:PYTHON_VERSION = '3.6'
& ((Split-Path $MyInvocation.InvocationName) + "\build_packages.ps1")
checkLastExitCode

$env:STABLE = 'false'

$env:PYTHON_VERSION = '2.7'
& ((Split-Path $MyInvocation.InvocationName) + "\build_packages.ps1")
checkLastExitCode

$env:PYTHON_VERSION = '3.5'
& ((Split-Path $MyInvocation.InvocationName) + "\build_packages.ps1")
checkLastExitCode

$env:PYTHON_VERSION = '3.6'
& ((Split-Path $MyInvocation.InvocationName) + "\build_packages.ps1")
checkLastExitCode
