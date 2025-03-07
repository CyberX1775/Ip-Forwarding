# ip-forwarding

## How It Works?
### Request Path:
#### Client => Routing VPS => Main VPS
All client requests are forwarded through the Routing VPS to the Main VPS.

### Response Path:
#### Main VPS => Routing VPS => Client

## Responses are dynamically routed back through the same Routing VPS that forwarded the request. This ensures that the Main VPS remains anonymous, and all traffic appears to originate from the Routing VPS.


### Routing-VPS
wget https://raw.githubusercontent.com/kervenov/ip-forwarding/main/routing-vps.sh

chmod +x routing-vps.sh

./routing-vps.sh

### Main-VPS
wget https://raw.githubusercontent.com/kervenov/ip-forwarding/main/main-vps.sh

chmod +x main-vps.sh

./main-vps.sh
