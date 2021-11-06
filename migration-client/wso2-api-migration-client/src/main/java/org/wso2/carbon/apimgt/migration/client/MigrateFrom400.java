/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.wso2.carbon.apimgt.migration.client;

import javafx.collections.transformation.SortedList;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.wso2.carbon.apimgt.api.APIManagementException;
import org.wso2.carbon.apimgt.api.model.API;
import org.wso2.carbon.apimgt.api.model.APIIdentifier;
import org.wso2.carbon.apimgt.impl.APIConstants;
import org.wso2.carbon.apimgt.impl.utils.APIUtil;
import org.wso2.carbon.apimgt.impl.utils.APIVersionComparator;
import org.wso2.carbon.apimgt.migration.APIMigrationException;
import org.wso2.carbon.apimgt.migration.client.internal.ServiceHolder;
import org.wso2.carbon.apimgt.migration.client.sp_migration.APIMStatMigrationException;
import org.wso2.carbon.apimgt.migration.dao.APIMgtDAO;
import org.wso2.carbon.apimgt.migration.util.Constants;
import org.wso2.carbon.apimgt.migration.util.RegistryService;
import org.wso2.carbon.context.PrivilegedCarbonContext;
import org.wso2.carbon.governance.api.generic.GenericArtifactManager;
import org.wso2.carbon.governance.api.generic.dataobjects.GenericArtifact;
import org.wso2.carbon.governance.api.util.GovernanceUtils;
import org.wso2.carbon.registry.api.RegistryException;
import org.wso2.carbon.registry.core.Registry;
import org.wso2.carbon.registry.core.RegistryConstants;
import org.wso2.carbon.registry.core.session.UserRegistry;
import org.wso2.carbon.user.api.Tenant;
import org.wso2.carbon.user.api.UserStoreException;
import org.wso2.carbon.user.core.tenant.TenantManager;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.stream.Collectors;

public class MigrateFrom400 extends MigrationClientBase implements MigrationClient {

    APIMgtDAO apiMgtDAO = APIMgtDAO.getInstance();
    private static final Log log = LogFactory.getLog(MigrateFrom400.class);
    private RegistryService registryService;

    public MigrateFrom400(String tenantArguments, String blackListTenantArguments, String tenantRange,
                          RegistryService registryService, TenantManager tenantManager) throws UserStoreException {

        super(tenantArguments, blackListTenantArguments, tenantRange, tenantManager);
        this.registryService = registryService;

    }

    @Override
    public void databaseMigration() throws APIMigrationException, SQLException {

        populateApiCategoryOrganizations();
        populateApiOrganizations();
        populateApplicationOrganizations();
    }

    private void populateApiCategoryOrganizations() throws APIMigrationException {

        try {
            Map<Integer, String> tenantIdsAndOrganizations = APIUtil.getAllTenantsWithSuperTenant().stream()
                    .collect(Collectors.toMap(Tenant::getId, Tenant::getDomain));
            apiMgtDAO.updateApiCategoryOrganizations(tenantIdsAndOrganizations);
        } catch (UserStoreException e) {
            throw new APIMigrationException("Failed to retrieve tenants");
        }
    }

    private void populateApiOrganizations() throws APIMigrationException {

        apiMgtDAO.updateApiOrganizations();
    }

    private void populateApplicationOrganizations() throws APIMigrationException {

        Map<Integer, String> subscriberOrganizations = new HashMap<>();
        Map<Integer, Integer> subscriberIdsAndTenantIds = apiMgtDAO.getSubscriberIdsAndTenantIds();
        for (Map.Entry<Integer, Integer> subscriberIdAndTenantId : subscriberIdsAndTenantIds.entrySet()) {
            String organization = APIUtil.getTenantDomainFromTenantId(subscriberIdAndTenantId.getValue());
            subscriberOrganizations.put(subscriberIdAndTenantId.getKey(), organization);
        }
        apiMgtDAO.updateApplicationOrganizations(subscriberOrganizations);
    }

    @Override
    public void registryResourceMigration() throws APIMigrationException {
        rxtMigration(registryService);
    }

    /**
     * This adds version timestamp to the rxt and db.
     *
     */
    public void migrationVersionTimestamp() {

        log.info("Vertion Timestamp migration for API Manager " + Constants.VERSION_4_0_0 + " started.");

        boolean isTenantFlowStarted = false;
        for (Tenant tenant : getTenantsArray()) {
            if (log.isDebugEnabled()) {
                log.debug("Start rxtMigration for tenant " + tenant.getId() + '(' + tenant.getDomain() + ')');
            }
            try {
                PrivilegedCarbonContext.startTenantFlow();
                isTenantFlowStarted = true;

                PrivilegedCarbonContext.getThreadLocalCarbonContext().setTenantDomain(tenant.getDomain(), true);
                PrivilegedCarbonContext.getThreadLocalCarbonContext().setTenantId(tenant.getId(), true);

                String adminName = ServiceHolder.getRealmService().getTenantUserRealm(tenant.getId())
                        .getRealmConfiguration().getAdminUserName();

                if (log.isDebugEnabled()) {
                    log.debug("Tenant admin username : " + adminName);
                }

                ServiceHolder.getTenantRegLoader().loadTenantRegistry(tenant.getId());
                Registry registry = ServiceHolder.getRegistryService().getGovernanceUserRegistry(adminName, tenant
                        .getId());
                GenericArtifactManager artifactManager = APIUtil.getArtifactManager(registry, APIConstants.API_KEY);

                if (artifactManager != null) {
                    GovernanceUtils.loadGovernanceArtifacts((UserRegistry) registry);
                    GenericArtifact[] artifacts = artifactManager.getAllGenericArtifacts();
                    Map<String, List<API>> apisMap = new TreeMap<>();
                    Map<API, GenericArtifact> apiToArtifactMapping = new HashMap<>();

                    for (GenericArtifact artifact : artifacts) {
                        try {
                            API api = APIUtil.getAPI(artifact, registry);
                            if (StringUtils.isNotEmpty(api.getVersionTimestamp())){
                                log.info("VersionTimestamp already available in APIName: " + api.getId().getApiName() +
                                        api.getId().getVersion());
                            }
                            if (api == null) {
                                log.error("Cannot find corresponding api for registry artifact " +
                                        artifact.getAttribute("overview_name") + '-' +
                                        artifact.getAttribute("overview_version") + '-' +
                                        artifact.getAttribute("overview_provider") +
                                        " of tenant " + tenant.getId() + '(' + tenant.getDomain() + ") in AM_DB");
                                continue;
                            }

                            if (log.isDebugEnabled()) {
                                log.debug("Doing the RXT migration for API : " +
                                        artifact.getAttribute("overview_name") + '-' +
                                        artifact.getAttribute("overview_version") + '-' +
                                        artifact.getAttribute("overview_provider") + '-' +
                                        artifact.getAttribute("version timestamp") + '-' +
                                        " of tenant " + tenant.getId() + '(' + tenant.getDomain() + ")");
                            }
                            if (!apisMap.containsKey(api.getId().getApiName())) {
                                List<API> versionedAPIsList = new ArrayList<>();
                                apisMap.put(api.getId().getApiName(), versionedAPIsList);

                            }
                            apisMap.get(api.getId().getApiName()).add(api);
                            if (!apiToArtifactMapping.containsKey(api)) {
                                apiToArtifactMapping.put(api, artifact);
                            }
                        } catch (Exception e) {
                            // we log the error and continue to the next resource.
                            log.error("Unable to migrate api metadata definition of API : " +
                                    artifact.getAttribute("overview_name") + '-' +
                                    artifact.getAttribute("overview_version") + '-' +
                                    artifact.getAttribute("overview_provider"), e);
                        }
                    }
                    // set the versionTimestamp for each API
                    for (String apiName : apisMap.keySet()) {
                        List<API> versionedAPIList = apisMap.get(apiName);
                        versionedAPIList.sort(new APIVersionComparator());
                        long timestamp = System.currentTimeMillis();
                        long oneDay = 86400;
                        for (int i = versionedAPIList.size(); i > 0; i--) {
                            API apiN = versionedAPIList.get(i - 1);
                            apiN.setVersionTimestamp(timestamp + "");
                            apiToArtifactMapping.get(apiN).setAttribute("overview_versionTimestamp",
                                    String.valueOf(timestamp));
                            artifactManager.updateGenericArtifact(apiToArtifactMapping.get(apiN));
                            log.info("VersionTimestamp updated API: " + apiN.getId().getApiName() + " version: " +
                                    apiN.getId().getVersion() + " timestamp: " + timestamp);
                            timestamp -= oneDay;
                        }
                        try {
                            apiMgtDAO.populateApiVersionTimestamp(versionedAPIList);
                        } catch (APIMigrationException e) {
                            log.error("Exception while populating version timestamp for api " + apiName +
                                    " tenant: " + tenant.getDomain());
                        }
                    }
                } else {
                    if (log.isDebugEnabled()) {
                        log.debug("No api artifacts found in registry for tenant " + tenant.getId() + '(' + tenant
                                .getDomain() + ')');
                    }
                }
            } catch (APIManagementException e) {
                log.error("Error occurred while reading API from the artifact ", e);
            } catch (RegistryException e) {
                log.error("Error occurred while accessing the registry", e);
            } catch (UserStoreException e) {
                log.error("Error occurred while reading tenant information", e);
            } finally {
                if (isTenantFlowStarted) {
                    PrivilegedCarbonContext.endTenantFlow();
                }
            }
            if (log.isDebugEnabled()) {
                log.debug("End rxtMigration for tenant " + tenant.getId() + '(' + tenant.getDomain() + ')');
            }
        }
        log.info("Rxt resource migration done for all the tenants");
    }

    @Override
    public void fileSystemMigration() throws APIMigrationException {

    }

    @Override
    public void cleanOldResources() throws APIMigrationException {

    }

    @Override
    public void statsMigration() throws APIMigrationException, APIMStatMigrationException {

    }

    @Override
    public void tierMigration(List<String> options) throws APIMigrationException {

    }

    @Override
    public void updateArtifacts() throws APIMigrationException {

    }

    @Override
    public void populateSPAPPs() throws APIMigrationException {

    }

    @Override
    public void populateScopeRoleMapping() throws APIMigrationException {

    }

    @Override
    public void scopeMigration() throws APIMigrationException {

    }

    @Override
    public void spMigration() throws APIMigrationException {

    }

    @Override
    public void updateScopeRoleMappings() throws APIMigrationException {

        for (Tenant tenant : getTenantsArray()) {
            loadAndSyncTenantConf(tenant.getId());
        }
    }
}
