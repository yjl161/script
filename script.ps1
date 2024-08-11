foreach($Adapter in Get-NetAdapter)
{
    New-NetIPAddress –IPAddress [IPAdresse] -DefaultGateway [Gateway] -PrefixLength [CIDR] -InterfaceIndex $Adapter.InterfaceIndex
}
