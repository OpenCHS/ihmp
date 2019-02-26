# <makefile>
# Objects: refdata, package
# Actions: clean, build, deploy
help:
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
	for help_line in $${help_lines[@]}; do \
	    IFS=$$'#' ; \
	    help_split=($$help_line) ; \
	    help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
	    help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
	    printf "%-30s %s\n" $$help_command $$help_info ; \
	done
# </makefile>

port:= $(if $(port),$(port),8021)
server:= $(if $(server),$(server),http://localhost)
server_url:=$(server):$(port)
su:=$(shell id -un)
org_name=IHMP
org_admin_name=ihmp-admin

poolId:=
clientId:=
username:=ihmp-admin
password:=

auth:
	$(if $(poolId),$(eval token:=$(shell node scripts/token.js $(poolId) $(clientId) $(username) $(password))))
	echo $(token)

auth_live:
	make auth poolId=$(OPENCHS_PROD_USER_POOL_ID) clientId=$(OPENCHS_PROD_APP_CLIENT_ID) username=ihmp-admin password=$(OPENCHS_PROD_ADMIN_USER_PASSWORD)

define _curl
	curl -X $(1) $(server_url)/$(2) -d $(3)  \
		-H "Content-Type: application/json"  \
		-H "USER-NAME: $(org_admin_name)"  \
		$(if $(token),-H "AUTH-TOKEN: $(token)",)
	@echo
	@echo
endef

define _curl_as_openchs
	curl -X $(1) $(server_url)/$(2) -d $(3)  \
		-H "Content-Type: application/json"  \
		-H "USER-NAME: admin"  \
		$(if $(token),-H "AUTH-TOKEN: $(token)",)
	@echo
	@echo
endef

create_org:  ;psql -U$(su) openchs < create_organisation.sql
create_views:  ;psql -U$(su) openchs < create_views.sql


deploy_checklists:
	$(call _curl,POST,concepts,@child/checklistConcepts.json)
	$(call _curl,POST,forms,@child/checklistForm.json)
	$(call _curl,POST,checklistDetail,@child/checklist.json)

# <deploy>
deploy_locations: auth
	$(call _curl,POST,locations,@address_level/phc.json)
	$(call _curl,POST,locations,@address_level/subcenter.json)
	$(call _curl,POST,locations,@address_level/village.json)
	$(call _curl,POST,locations,@address_level/slum.json)

deploy_org_data: deploy_locations
	$(call _curl,POST,catchments,@catchments.json)

create_admin_user:
	$(call _curl_as_openchs,POST,users,@admin-user.json)

create_admin_user_dev:
	$(call _curl_as_openchs,POST,users,@users/dev-admin-user.json)

create_users_dev:
	$(call _curl,POST,users,@users/dev-users.json)

deploy_org_data_live:
	make auth deploy_org_data poolId=$(STAGING_USER_POOL_ID) clientId=$(STAGING_APP_CLIENT_ID) username=ihmp-admin password=$(STAGING_ADMIN_USER_PASSWORD)

deploy_subjects:
	$(call _curl,POST,operationalSubjectTypes,@operationalModules/operationalSubjectTypes.json)

_deploy_refdata: deploy_subjects
	$(call _curl,POST,concepts,@registration/registrationConcepts.json)
	$(call _curl,POST,forms,@registration/registrationForm.json)
	$(call _curl,POST,programs,@programs.json)
	$(call _curl,POST,encounterTypes,@encounterTypes.json)
	$(call _curl,POST,operationalEncounterTypes,@operationalModules/operationalEncounterTypes.json)
	$(call _curl,POST,operationalPrograms,@operationalModules/operationalPrograms.json)
	$(call _curl,POST,concepts,@eligibleCouple/eligibleCoupleConcepts.json)
	$(call _curl,POST,forms,@eligibleCouple/eligibleCoupleEnrolmentForm.json)
	$(call _curl,POST,forms,@eligibleCouple/monthlyNeedsAssessmentForm.json)
	$(call _curl,POST,forms,@eligibleCouple/fpServicesForm.json)
	$(call _curl,POST,forms,@eligibleCouple/rtiServicesForm.json)
	$(call _curl,POST,forms,@census/censusForm.json)

	$(call _curl,POST,forms,@eligibleCouple/ecProgramExitForm.json)

	$(call _curl,POST,concepts,@pregnancy/pregnancyConcepts.json)
	$(call _curl,DELETE,forms,@pregnancy/enrolmentDeletions.json)
	$(call _curl,PATCH,forms,@pregnancy/enrolmentAdditions.json)
	$(call _curl,POST,concepts,@pregnancy/pncConcepts.json)
	$(call _curl,DELETE,forms,@pregnancy/pncDeletions.json)
	$(call _curl,PATCH,forms,@pregnancy/pncAdditions.json)
	$(call _curl,PATCH,forms,@pregnancy/abortionAdditions.json)
	$(call _curl,POST,forms,@pregnancy/ancvhndForm.json)
	$(call _curl,POST,forms,@pregnancy/ancvhndfollowupForm.json)
	$(call _curl,POST,forms,@pregnancy/ancashaForm.json)
	$(call _curl,DELETE,forms,@pregnancy/deliveryDeletions.json)
	$(call _curl,PATCH,forms,@pregnancy/deliveryAdditions.json)
	$(call _curl,POST,concepts,@child/childConcepts.json)
	$(call _curl,POST,forms,@child/nutritionalStatusForm.json)

	$(call _curl,POST,forms,@shared/encounterCancellation/encounterCancellationForm.json)

	$(call _curl,POST,formMappings,@formMappings.json)


deploy_rules:
	node index.js "$(server_url)" "$(token)" "$(username)"

deploy_rules_live:
	make auth deploy_rules poolId=$(OPENCHS_PROD_USER_POOL_ID) clientId=$(OPENCHS_PROD_APP_CLIENT_ID) username=ihmp-admin password=$(password) server=https://server.openchs.org port=443

deploy_refdata: deploy_org_data _deploy_refdata

deploy: create_admin_user_dev deploy_refdata deploy_checklists deploy_rules create_users_dev##

_deploy_prod: deploy_refdata deploy_checklists deploy_rules

deploy_prod:
#	there is a bug in server side. which sets both isAdmin, isOrgAdmin to be false. it should be done. also metadata upload should not rely on isAdmin role.
#	need to be fixed. then uncomment the following line.
#	make auth deploy_admin_user poolId=ap-south-1_DU27AHJvZ clientId=1d6rgvitjsfoonlkbm07uivgmg server=https://server.openchs.org port=443 username=admin password=
	make auth _deploy_prod poolId=$(OPENCHS_PROD_USER_POOL_ID) clientId=$(OPENCHS_PROD_APP_CLIENT_ID) server=https://server.openchs.org port=443 username=ihmp-admin password=$(password)


create_deploy: create_org deploy ##

deploy_staging:
	make auth _deploy_prod poolId=$(OPENCHS_STAGING_USER_POOL_ID) clientId=$(OPENCHS_STAGING_APP_CLIENT_ID) server=https://staging.openchs.org port=443 username=ihmp-admin password=$(password)

deploy_uat:
	make auth _deploy_prod poolId=$(OPENCHS_UAT_USER_POOL_ID) clientId=$(OPENCHS_UAT_APP_CLIENT_ID) server=https://uat.openchs.org port=443 username=ihmp-admin password=$(password)

deploy_rules_uat:
	make auth deploy_rules poolId=$(OPENCHS_UAT_USER_POOL_ID) clientId=$(OPENCHS_UAT_APP_CLIENT_ID) server=https://uat.openchs.org port=443 username=ihmp-admin password=$(password)

deploy_rules_staging:
	make auth deploy_rules poolId=$(OPENCHS_STAGING_USER_POOL_ID) clientId=$(OPENCHS_STAGING_APP_CLIENT_ID) server=https://staging.openchs.org port=443 username=ihmp-admin password=$(password)


create_admin_user_staging:
	make auth create_admin_user poolId=$(OPENCHS_STAGING_USER_POOL_ID) clientId=$(OPENCHS_STAGING_APP_CLIENT_ID) server=https://staging.openchs.org port=443 username=admin password=$(password)

_create_users_staging:
	$(call _curl,POST,users,@users/staging-users.json)

create_users_staging:
	make auth _create_users_staging poolId=$(OPENCHS_STAGING_USER_POOL_ID) clientId=$(OPENCHS_STAGING_APP_CLIENT_ID) server=https://staging.openchs.org port=443 username=ihmp-admin password=$(password)



# <package>
build_package: ## Builds a deployable package
	rm -rf output/impl
	mkdir -p output/impl
	cp registrationForm.json catchments.json deploy.sh output/impl
	cd output/impl && tar zcvf ../openchs_impl.tar.gz *.*
# </package>

deps:
	npm i

by_org_admin:
	$(eval username:=$(org_admin_name))

staging:
	$(eval poolId:=$(OPENCHS_STAGING_USER_POOL_ID))
	$(eval clientId:=$(OPENCHS_STAGING_APP_CLIENT_ID))
	$(eval server_url:= https://staging.openchs.org:443)

prod:
	$(eval poolId:=$(OPENCHS_PROD_USER_POOL_ID))
	$(eval clientId:=$(OPENCHS_PROD_APP_CLIENT_ID))
	$(eval server_url:= https://server.openchs.org:443)

dev:
	$(eval poolId:=)
	$(eval clientId:=)
	$(eval server_url:=http://localhost:8021)

api=
file=
method=
curl_staging: staging by_org_admin auth #password=password
	$(eval method:=$(if $(method),$(method),POST))
	$(call _curl,$(method),$(api),@$(file))

# ex: make curl_prod api=concepts file=child/homeVisitConcepts.json password=
curl_prod: prod by_org_admin auth #password=password
	$(eval method:=$(if $(method),$(method),POST))
	$(call _curl,$(method),$(api),@$(file))

curl_dev: dev by_org_admin
	$(eval method:=$(if $(method),$(method),POST))
	$(call _curl,$(method),$(api),@$(file))

define _curl_for_form_query_export
	@curl -X GET '$(server_url)/query/program/$(1)/encounter/$(2)'  \
		-H "Content-Type: application/json"  \
		-H "USER-NAME: $(org_admin_name)"  \
		$(if $(token),-H "AUTH-TOKEN: $(token)",)
	@echo
	@echo
endef

define _curl_for_all_forms_query_export
	@curl -X GET '$(server_url)/query/program/$(1)'  \
		-H "Content-Type: application/json"  \
		-H "USER-NAME: $(org_admin_name)"  \
		$(if $(token),-H "AUTH-TOKEN: $(token)",)
	@echo
	@echo
endef

program=
encounter-type=
get_forms:
	$(call _curl_for_form_query_export,$(program),$(encounter-type))

get_all_forms:
	$(call _curl_for_all_forms_query_export,$(program))
