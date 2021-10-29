#!/bin/bash

# Enviroments
transition='https://internal-api.mercadolibre.com/capacity-transition/routes/query'
stage='https://internal-api.mercadolibre.com/capacity-stage/routes/query'
localhost='https://localhost:8080/routes/query'
production='https://internal-api.mercadolibre.com/capacity-location/routes/query'

# Default Shipment settings
serviceid="277350"
tzone="SLA1"
country="AR"
carrier_date=`date +"%Y-%m-%d"`

# Default Environment
targetserver=$stage

# Default template 
TEMPLATES_FOLDER=.
#TEMPLATE_FILE=template-fulfillment.json 
TEMPLATE_FILE=template-self_service.json 


select-server() {
	case $1	in
		stage)	targetserver=$stage
			;;
		local)	targetserver=$localhost
			;;
		production)	targetserver=$production
			;;
		transition)	targetserver=$transition
			;;
	esac
}

select-logistictype() {
	case $1	in
		full)	TEMPLATE_FILE=template-fulfillment.json 
			;;
		self)	TEMPLATE_FILE=template-self_service.json 
			;;
	esac
}

while getopts 'c:hs:t:d:e:l:' OPTION
do
	case $OPTION in
		c)	country="$OPTARG"
			;;
		s)	serviceid="$OPTARG"
			;;
		t)	tzone="$OPTARG"
			;;
		d)	carrier_date="$OPTARG"
			;;
		e)	select-server "$OPTARG"
			;;
		l)	select-logistictype "$OPTARG"
			;;
		h)	printf "Usage: %s: [-e environment] [-c country_code] [-s value] [-t value] [-d carrier_date]\n" $(basename $0) >&2
			exit 2
			;;
	esac
done
shift $(($OPTIND - 1))

request=`cat $TEMPLATES_FOLDER/$TEMPLATE_FILE| sed "s/:service_id/$serviceid/g" | sed "s/:tzone_id/$tzone/g" | sed "s/:country_id/$country/g" | sed "s/:carrier_date/$carrier_date/g"`

curl --location --request POST $targetserver --header 'Content-Type: application/json' --data-binary "$request" | jq ".routes[0].steps[1].capacity_data" 2>/dev/null
