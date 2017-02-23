#!/usr/bin/env bash
	
DUMPSDIRECTORY=dumps
	
read -p "Would you like to dump data [y/N]:" DUMPDATA
	
if [ "$DUMPDATA" = "y" ]; then
	
	# Get database connection details
	read -p "Enter source host IP address: " SOURCE_HOST

	read -p "Enter source database name: " SOURCE_DATABASE

	read -p "Enter source database usename: " SOURCE_DATABASE_USERNAME

	echo -n "Enter source database password for '$SOURCE_DATABASE_USERNAME': "

	read -s SOURCE_DATABASE_PASSWORD

	echo

	# Get query range details
	read -p "Enter query start date (format YYYY-mm-dd):" STARTDATE

	read -p "Enter query end date (format YYYY-mm-dd):" ENDDATE

	mkdir -p $DUMPSDIRECTORY/

	# Tables:
	# encounter, obs, drug_order, orders, users, person, person_name, 
	# person_address, patient_program, patient, patient_identifier, person_attribute

	for table in "obs" "orders" "person_address" "patient_program" "patient_identifier"; 
	do

		echo "Dumping $table...";
	
		mysqldump --opt -h$SOURCE_HOST -u$SOURCE_DATABASE_USERNAME -p$SOURCE_DATABASE_PASSWORD --no-create-info --replace --where "DATE(date_created) >= DATE(\"$STARTDATE\") AND DATE(date_created) <= DATE(\"$ENDDATE\")" $SOURCE_DATABASE $table > "dumps/$table.sql"
	
	done

	for table in "encounter" "users" "person" "person_name" "patient" "person_attribute"; 
	do

		echo "Dumping $table...";
	
		mysqldump --opt -h$SOURCE_HOST -u$SOURCE_DATABASE_USERNAME -p$SOURCE_DATABASE_PASSWORD --no-create-info --replace --where "(DATE(date_created) >= DATE(\"$STARTDATE\") AND DATE(date_created) <= DATE(\"$ENDDATE\")) OR (DATE(date_changed) >= DATE(\"$STARTDATE\") AND DATE(date_changed) <= DATE(\"$ENDDATE\"))" $SOURCE_DATABASE $table > "dumps/$table.sql"
	
	done

	# drug_order
	echo "Dumping drug_order...";

	mysqldump --opt --lock-all-tables -h$SOURCE_HOST -u$SOURCE_DATABASE_USERNAME -p$SOURCE_DATABASE_PASSWORD --no-create-info --replace --where "order_id IN (SELECT order_id FROM orders WHERE DATE(date_created) >= DATE(\"$STARTDATE\") AND DATE(date_created) <= DATE(\"$ENDDATE\"))" $SOURCE_DATABASE drug_order > "dumps/$table.sql";

fi

if [ -d "$DUMPSDIRECTORY" ]; then 
		
	read -p "Would you like to load data [y/N]:" LOADDATA
	
	if [ "$LOADDATA" = "y" ]; then
	
		clear
	
		# Get database connection details
		read -p "Enter destination host IP address: " DESTINATION_HOST

		read -p "Enter destination database name: " DESTINATION_DATABASE

		read -p "Enter destination database usename: " DESTINATION_DATABASE_USERNAME

		echo -n "Enter destination database password for '$DESTINATION_DATABASE_USERNAME': "

		read -s DESTINATION_DATABASE_PASSWORD

		for filename in $DUMPSDIRECTORY/*.sql; do
		
			echo "Loading $filename...";
						
			mysql -h $DESTINATION_HOST -u $DESTINATION_DATABASE_USERNAME -p$DESTINATION_DATABASE_PASSWORD $DESTINATION_DATABASE < $filename;
		
		done

	echo

	fi	

fi
