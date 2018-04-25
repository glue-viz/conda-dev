# We use the following function to exit the script after any failing command
function checkLastExitCode {
  if ($lastExitCode) {
    echo "ERROR: the last command returned the following exit code: $lastExitCode"
    Exit $lastExitCode
  }
}

$env:STABLE = true

$env:PYTHON_VERSION = 2.7
& ((Split-Path $MyInvocation.InvocationName) + "\build_pacakges.ps1")
checkLastExitCode

$env:PYTHON_VERSION = 3.5
& ((Split-Path $MyInvocation.InvocationName) + "\build_pacakges.ps1")
checkLastExitCode

$env:PYTHON_VERSION = 3.6
& ((Split-Path $MyInvocation.InvocationName) + "\build_pacakges.ps1")
checkLastExitCode

$env:STABLE = false

$env:PYTHON_VERSION = 2.7
& ((Split-Path $MyInvocation.InvocationName) + "\build_pacakges.ps1")
checkLastExitCode

$env:PYTHON_VERSION = 3.5
& ((Split-Path $MyInvocation.InvocationName) + "\build_pacakges.ps1")
checkLastExitCode

$env:PYTHON_VERSION = 3.6
& ((Split-Path $MyInvocation.InvocationName) + "\build_pacakges.ps1")
checkLastExitCode
