
# Define the target and threshold
$target = "google.com"
$threshold = 70  #set this to whatever you need to

# Generate the CSV file path with the current date and hour
$dateTime = Get-Date -Format "yyyyMMdd_HH"
$csvFilePath = "ping_results_$dateTime.csv"

# Function to emit a low-frequency beep
function LowBeep {
    [console]::Beep(400, 500)  # 400 Hz for 500 ms
}

# Function to emit a high-frequency beep
function HighBeep {
    [console]::Beep(1000, 500)  # 1000 Hz for 500 ms
}

# Function to get the connected WiFi network name and band
function GetWiFiNetworkInfo {
     $networkInfo = (netsh wlan show interfaces | Select-String "SSID")
     $wifiName = $networkInfo -replace '.*:\s*'
     return $wifiName
 }

# Check if the CSV file exists, if not create it and add headers
if (-Not (Test-Path $csvFilePath)) {
    "Timestamp,Host,ResponseTime,Status,Message" | Out-File -FilePath $csvFilePath -Encoding UTF8
}

# Infinite loop to continuously ping, with user input to terminate
while ($true) {
    # Get the current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

 # Get the connected WiFi network name and band
   $wifiNetwork= GetWiFiNetworkInfo

    # Perform the ping
    $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue

    # Initialize variables for CSV entry
    $responseTime = ""
    $status = ""
    $message = ""

    # Check if the ping was successful
    if ($ping) {
        foreach ($result in $ping) {
            $responseTime = $result.ResponseTime
            if ($responseTime -gt $threshold) {
                $message = "Response time too high: $responseTime ms"
                Write-Host $message -ForegroundColor Yellow
                LowBeep
                $status = "High Response Time"
            } else {
                $message = "Ping successful: $responseTime ms"
                Write-Host $message -ForegroundColor Green
                $status = "Success"
            }
        }
    } else {
        $message = "Ping failed. Packet loss detected.[$wifiNetwork]"
        Write-Host $message -ForegroundColor Red
        HighBeep
        $responseTime = "N/A"
        $status = "Packet Loss"
    }

    # Write the results to the CSV file
    "$timestamp, $wifiNetwork, $wifiBand , $target, $responseTime, $status, $message" | Out-File -FilePath $csvFilePath -Append

    # Check for user input to terminate the loop
    if ($host.UI.RawUI.KeyAvailable) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        if ($key.Character -eq 'q') {
            Write-Host "Termination requested by user. Exiting..." -ForegroundColor Cyan
            break
        }
    }

    # Wait for a second before the next ping
    Start-Sleep -Seconds 1
}
# credits : chat gpt
