#!/bin/bash

loop=true

set_quick_deployment_vars () {
	ENV_NAME="prod"
    REALM="auth"
	ENTITY_NAME="keycloak"
	COUNTRY_CODE="com"
	AUTOSCALE=false
	REPLICAS=1
	KC_USERNAME="admin"
	KC_PASSWORD="password"
	PG_USERNAME="admin"
	PG_PASSWORD="password"
	if [ "${ENV_NAME}" = "prod" ]; then
			NAMESPACE=kc-${REALM}-${ENTITY_NAME}-${COUNTRY_CODE};
			ING_HOSTNAME=${REALM}.${ENTITY_NAME}.${COUNTRY_CODE};
		else
			NAMESPACE=kc-${REALM}-${ENTITY_NAME}-${COUNTRY_CODE}-${ENV_NAME};
			ING_HOSTNAME=${REALM}-${ENV_NAME}.${ENTITY_NAME}.${COUNTRY_CODE};
	fi
	echo "Deploying Keycloak & Postgresql in $ENV_NAME environment..."
	echo "Keycloak credentials: $KC_USERNAME:$KC_PASSWORD"
	echo "Postgres credentials: $PG_USERNAME:$PG_PASSWORD"
	export pod_name=${REALM};
	export autoscale=${AUTOSCALE};
	export replicas=${REPLICAS};
	export kc_username=${KC_USERNAME};
	export kc_password=${KC_PASSWORD};
	export pg_username=${PG_USERNAME};
	export pg_password=${PG_PASSWORD};
	export ing_hostname=${ING_HOSTNAME};
	export tls_secret=${ENTITY_NAME}-${COUNTRY_CODE}-tls;
	export namespace=${NAMESPACE};

	rm -f values.yaml tmp.yaml  
	( echo "cat <<EOF >values.yaml";
	cat template.yaml;
	) >tmp.yaml
	. tmp.yaml
	rm -f tmp.yaml >/dev/null
}

set_deployment_vars () {
	read -p "Environnement name [dev|preprod|prod]                     : " ENV_NAME;
	read -p "Entity name                                               : " ENTITY_NAME;
	read -p "Country code                                              : " COUNTRY_CODE;
    read -p "Subdomain (Realm)                                         : " REALM;
	read -p "Enable autoscaling [y/n]                                  : " AUTOSCALE;
	if [ "${AUTOSCALE}" = "Y" ] || [ "${AUTOSCALE}" = "y" ] || [ "${AUTOSCALE}" = "yes" ] || [ "${AUTOSCALE}" = "YES" ] ; then
		AUTOSCALE=true;
		REPLICAS=0;
	else
		AUTOSCALE=false;
		read -p "Number of Keycloak replicas                               : " REPLICAS;
	fi
	read -p "Username for the Keycloak admin user                      : " KC_USERNAME;
	read -p "Password for the Keycloak admin user                      : " KC_PASSWORD;
	if [ "$1" = "postgresql" ] || [ "$1" = "Postgresql" ] || [ "$1" = "POSGRESQL" ] ; then
		read -p "Username for the Postgres admin user                      : " PG_USERNAME;
		read -p "Password for the Postgres admin user                      : " PG_PASSWORD;
		export pg_username=${PG_USERNAME};
		export pg_password=${PG_PASSWORD};
	else
		echo "Deploying Keycloak with existing database..."
		read -p "The database vendor [postgres|mysql|oracle..]             : " DB_VENDOR;
		read -p "The database host (******.mysql.database.azure.com)       : " DB_HOST;
		read -p "The database port (3306)                                  : " DB_PORT;
		read -p "The database name (******)                                : " DB_NAME;
		read -p "The database username (******@******)		               : " DB_USERNAME;
		read -p "The database password (******)                            : " DB_PASSWORD;
		export db_vendor=${DB_VENDOR};
		export db_host=${DB_HOST};
		export db_name=${DB_NAME};
		export db_port=${DB_PORT};
		export db_username=${DB_USERNAME};
		export db_password=${DB_PASSWORD};
	fi
	if [ "${ENV_NAME}" = "prod" ]; then
			NAMESPACE=kc-${REALM}-${ENTITY_NAME}-${COUNTRY_CODE};
			ING_HOSTNAME=${REALM}.${ENTITY_NAME}.${COUNTRY_CODE};
		else
			NAMESPACE=kc-${REALM}-${ENTITY_NAME}-${COUNTRY_CODE}-${ENV_NAME};
			ING_HOSTNAME=${REALM}-${ENV_NAME}.${ENTITY_NAME}.${COUNTRY_CODE};
	fi
	export pod_name=${REALM};
	export autoscale=${AUTOSCALE};
	export replicas=${REPLICAS};
	export kc_username=${KC_USERNAME};
	export kc_password=${KC_PASSWORD};
	export ing_hostname=${ING_HOSTNAME};
	export tls_secret=${ENTITY_NAME}-${COUNTRY_CODE}-tls;
	export namespace=${NAMESPACE};

	rm -f values.yaml tmp.yaml  
	( echo "cat <<EOF >values.yaml";
	cat template.yaml;
	) >tmp.yaml
	. tmp.yaml
	rm -f tmp.yaml >/dev/null
}

create_certs () {
	echo "Creating tls certificates..."
	rm -rf ./certs/tls.* >/dev/null
	mkdir -p ./certs >/dev/null
	mkcert -cert-file certs/tls.crt -key-file certs/tls.key "$1.$2" "*.$1.$2"
	kubectl create secret tls $1-$2-tls --namespace=$3 --cert=certs/tls.crt --key=certs/tls.key
}

helm_install () {
	# $1: NAMESPACE
	# $2: VALUES FILE
	# $3: IMAGE REPOSITORY
	# $4: IMAGE TAG
	# $5: HELM CHART PATH
	echo "Deploying Keycloak in $1 namespace using $2 Helm chart..."
	helm install keycloak \
		--namespace $1 \
		--values $2 \
		--set image.repository=$3 \
        --set image.tag=$4 \
		$5
}

helm_upgrade () {
	# $1: NAMESPACE
	# $2: VALUES FILE
	# $3: IMAGE REPOSITORY
	# $4: IMAGE TAG
	# $5: HELM CHART PATH
	echo "Deploying Keycloak in $1 namespace using $2 Helm chart..."
	helm upgrade keycloak \
        --namespace $1 \
        --create-namespace \
        --install \
        --wait \
		--values $2 \
        --set image.repository=$3 \
        --set image.tag=$4 \
		$5
}

while [[ $loop ]]; 
do 
	clear
	echo '-------*~                                           ~*-------------
    ___  __.                  .__                __    
    |   |/ _|____ ___.__. ____ |  |   _________  |  | __
    |     <_/ __ <   |  |/ ___\|  |  /  _ \__  \ |  |/ /
    |   |  \  ___/\___  \  \___|  |_(  <_> ) __ \|    < 
    |___|___\____ >\____|\____/\____/\____(____  /__|___\ V12.0.4

Welcome on Keycloak deployment in Kubernetes cluster

Name:			Keycloak
Description:		Open Source Identity and Access Management 
			For Modern Applications and Services

Keycloak version:	12.0.4
Helm chart version:	11.0.1
Documentation:		https://www.keycloak.org/documentation.html

Sources:
    - https://quay.io/repository/keycloak/keycloak
    - https://github.com/codecentric/helm-charts

Menu:
  1. Deploy Keycloak & Postgresql
  2. Deploy Keycloak
  3. List deployment
  4. Exit'
	echo "-------------------------------------------------------------------"

	read  MENU_CHOICE
	case "$MENU_CHOICE" in
	1)  read -p "Quick deployment [y/n]                : " QUICK;
		if [ "${QUICK}" = "Y" ] || [ "${QUICK}" = "y" ] || [ "${QUICK}" = "yes" ] || [ "${QUICK}" = "YES" ] ; then
			set_quick_deployment_vars
		else
			set_deployment_vars postgresql
		fi
		kubectl create namespace ${NAMESPACE} 
		create_certs ${ENTITY_NAME} ${COUNTRY_CODE} ${NAMESPACE}
		helm_install ${NAMESPACE} values.yaml an455/kc12.0.4 latest ./keycloak-11.0.1.tgz

		read -s -n 1 -p "Press any key to continue..."
		;;
	2)  set_deployment_vars 
		kubectl create namespace ${NAMESPACE} 
		create_certs ${ENTITY_NAME} ${COUNTRY_CODE} ${NAMESPACE}
		helm_install ${NAMESPACE} values.yaml an455/kc12.0.4 latest ./keycloak-11.0.1.tgz

		read -s -n 1 -p "Press any key to continue..."
		;;
	3)  echo "Listing all deployment..."
		helm ls -A
		read -s -n 1 -p "Press any key to continue..."
		;;
	4)  echo "Goodbye!"
		loop=false
		break
		;;
	*)  echo "- Wrong choice! Please try again..."
		;;
	esac
done
