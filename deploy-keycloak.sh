#!/bin/bash

loop=true

print_menu () {
	clear
	echo '------*~                                                    ~*-----------------------
	 ___  __.                  .__                __    
	|   |/ _|____ ___.__. ____ |  |   _________  |  | __
	|     <_/ __ <   |  |/ ___\|  |  /  _ \__  \ |  |/ /
	|   |  \  ___/\___  \  \___|  |_(  <_> ) __ \|    < 
	|___|___\____ >\____|\____/\____/\____(____  /__|___\ V12.0.4

	Welcome on Keycloak deployment in Kubernetes cluster

	Name:			Keycloak
	Description:		Open Source Identity and Access Management For 
				Modern Applications and Services

	Keycloak version:	12.0.4
	Helm chart version:	11.0.1
	Documentation:		https://www.keycloak.org/documentation.html

	Sources:
		- https://quay.io/repository/keycloak/keycloak
		- https://github.com/codecentric/helm-charts

	Menu:
	-----
		1. Deploy Keycloak & Postgresql
		2. Deploy Keycloak
		3. List deployment
		4. Exit'
	echo "-------------------------------------------------------------------------------------"
}

set_quick_deployment_vars () {
	# $1: VALUES FILE
	if [ $# = 1 ] ; then
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
		rm -f $1 tmp.yaml  
		( echo "cat <<EOF >$1";
		cat template.yaml;
		) >tmp.yaml
		. tmp.yaml
		rm -f tmp.yaml >/dev/null
	else
		echo "ERROR set_quick_deployment_vars: Number of arguments error $*"
		echo "Usage: set_quick_deployment_vars VALUES_FILE"
		exit
	fi
}

set_deployment_vars () {
	# $1: VALUES FILE
	# $2: ENABLE POSTGRESQL [true|false]
	if [ $# = 2 ] ; then
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
		if [ "$2" = "true" ] || [ "$2" = "True" ] || [ "$2" = "TRUE" ] ; then
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
		rm -f $1 tmp.yaml  
		( echo "cat <<EOF >$1";
		cat template.yaml;
		) >tmp.yaml
		. tmp.yaml
		rm -f tmp.yaml >/dev/null
	else
		echo "ERROR set_deployment_vars: Number of arguments error $*"
		echo "Usage: set_deployment_vars VALUES_FILE ENABLE_POSTGRESQL"
		exit
	fi
}

create_certs () {
	# $1: ENTITY NAME
	# $2: COUNTRY CODE
	# $3: NAMESPACE
	if [ $# = 3 ] ; then
		echo "Creating tls certificates..."
		rm -rf ./certs/tls.* >/dev/null
		mkdir -p ./certs >/dev/null
		mkcert -cert-file certs/tls.crt -key-file certs/tls.key "$1.$2" "*.$1.$2"
		kubectl create secret tls $1-$2-tls --namespace=$3 --cert=certs/tls.crt --key=certs/tls.key
	else
		echo "ERROR create_certs: Number of arguments error $*"
		echo "Usage: create_certs ENTITY_NAME COUNTRY_CODE NAMESPACE"
		exit
	fi
}

helm_install () {
	# $1: RELEASE NAME
	# $2: NAMESPACE
	# $3: VALUES FILE
	# $4: IMAGE REPOSITORY
	# $5: IMAGE TAG
	# $6: HELM CHART PATH
	if [ $# = 6 ] ; then
		echo "Deploying Keycloak in $2 namespace using $3 Helm chart..."
		helm install $1 \
			--namespace $2 \
			--values $3 \
			--set image.repository=$4 \
			--set image.tag=$5 \
			$6
	else
		echo "ERROR helm_install: Number of arguments error $*"
		echo "Usage: helm_install RELEASE_NAME NAMESPACE VALUES_FILE IMAGE_REPOSITORY IMAGE_TAG HELM_CHART_PATH"
		exit
	fi
}

helm_upgrade_install () {
	# $1: RELEASE NAME
	# $2: NAMESPACE
	# $3: VALUES FILE
	# $4: IMAGE REPOSITORY
	# $5: IMAGE TAG
	# $6: HELM CHART PATH
	if [ $# = 6 ] ; then
		echo "Deploying Keycloak in $2 namespace using $3 Helm chart..."
		helm upgrade $1 \
			--namespace $2 \
			--create-namespace \
			--install \
			--recreate-pods \
			--force \
			--reset-values \
			--wait \
			--values $3 \
			--set image.repository=$4,image.tag=$5 \
			$6
	else
		echo "ERROR helm_upgrade: Number of arguments error $*"
		echo "Usage: helm_upgrade RELEASE_NAME NAMESPACE VALUES_FILE IMAGE_REPOSITORY IMAGE_TAG HELM_CHART_PATH"
		exit
	fi
}

main () {
	while [[ $loop ]]; 
	do 
		print_menu
		read  MENU_CHOICE
		case "$MENU_CHOICE" in
		1)  read -p "Quick deployment [y/n]                : " QUICK;
			if [ "${QUICK}" = "Y" ] || [ "${QUICK}" = "y" ] || [ "${QUICK}" = "yes" ] || [ "${QUICK}" = "YES" ] ; then
				set_quick_deployment_vars values.yaml
			else
				set_deployment_vars values.yaml true
			fi
			kubectl create namespace ${NAMESPACE} 
			create_certs ${ENTITY_NAME} ${COUNTRY_CODE} ${NAMESPACE}
			helm_install keycloak ${NAMESPACE} values.yaml an455/kc12.0.4 latest ./keycloak-11.0.1.tgz

			read -s -n 1 -p "Press any key to continue..."
			;;
		2)  set_deployment_vars values.yaml false
			kubectl create namespace ${NAMESPACE} 
			create_certs ${ENTITY_NAME} ${COUNTRY_CODE} ${NAMESPACE}
			helm_install keycloak ${NAMESPACE} values.yaml an455/kc12.0.4 latest ./keycloak-11.0.1.tgz

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
}

main
