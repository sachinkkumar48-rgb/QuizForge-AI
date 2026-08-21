param(
  [Parameter(Mandatory=$true, Position=0)]
  [ValidateSet("init","status","models","checkpoint","run","task")]
  [string]$Action,
  [Parameter(Position=1)]
  [string]$Name,
  [string]$Prompt,
  [string]$PromptFile,
  [string]$Model,
  [switch]$Continue,
  [string]$Conversation,
  [int]$Timeout,
  [string]$TaskFile,
  [switch]$DryRun
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$PyCmd = if (Get-Command py -ErrorAction SilentlyContinue) { "py" } else { "python" }

if ($Action -eq "run") {
  if (-not $Name) { throw "Task Name is required for 'run'." }
  $argsList = @("-m", "titan_agent", "run", $Name)
  if ($Prompt) { $argsList += @("--prompt", $Prompt) }
  if ($PromptFile) { $argsList += @("--prompt-file", $PromptFile) }
  if ($Model) { $argsList += @("--model", $Model) }
  if ($Continue) { $argsList += "--continue" }
  if ($Conversation) { $argsList += @("--conversation", $Conversation) }
  if ($Timeout) { $argsList += @("--timeout", $Timeout.ToString()) }
  & $PyCmd @argsList
} elseif ($Action -eq "task") {
  $file = if ($TaskFile) { $TaskFile } else { $Name }
  if (-not $file) { throw "Task file path is required for 'task'." }
  $argsList = @("-m", "titan_agent", "task", $file)
  if ($DryRun) { $argsList += "--dry-run" }
  & $PyCmd @argsList
} else {
  & $PyCmd -m titan_agent $Action
}
