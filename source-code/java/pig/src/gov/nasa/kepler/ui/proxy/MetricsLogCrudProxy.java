/*
 * Copyright 2017 United States Government as represented by the
 * Administrator of the National Aeronautics and Space Administration.
 * All Rights Reserved.
 * 
 * This file is available under the terms of the NASA Open Source Agreement
 * (NOSA). You should have received a copy of this agreement with the
 * Kepler source code; see the file NASA-OPEN-SOURCE-AGREEMENT.doc.
 * 
 * No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY
 * WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY,
 * INCLUDING, BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE
 * WILL CONFORM TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR FREEDOM FROM
 * INFRINGEMENT, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL BE ERROR
 * FREE, OR ANY WARRANTY THAT DOCUMENTATION, IF PROVIDED, WILL CONFORM
 * TO THE SUBJECT SOFTWARE. THIS AGREEMENT DOES NOT, IN ANY MANNER,
 * CONSTITUTE AN ENDORSEMENT BY GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT
 * OF ANY RESULTS, RESULTING DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY
 * OTHER APPLICATIONS RESULTING FROM USE OF THE SUBJECT SOFTWARE.
 * FURTHER, GOVERNMENT AGENCY DISCLAIMS ALL WARRANTIES AND LIABILITIES
 * REGARDING THIRD-PARTY SOFTWARE, IF PRESENT IN THE ORIGINAL SOFTWARE,
 * AND DISTRIBUTES IT "AS IS."
 * 
 * Waiver and Indemnity: RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS
 * AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND
 * SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT. IF RECIPIENT'S USE OF
 * THE SUBJECT SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES,
 * EXPENSES OR LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM
 * PRODUCTS BASED ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT
 * SOFTWARE, RECIPIENT SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED
 * STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY
 * PRIOR RECIPIENT, TO THE EXTENT PERMITTED BY LAW. RECIPIENT'S SOLE
 * REMEDY FOR ANY SUCH MATTER SHALL BE THE IMMEDIATE, UNILATERAL
 * TERMINATION OF THIS AGREEMENT.
 */

package gov.nasa.kepler.ui.proxy;

import gov.nasa.kepler.hibernate.dbservice.DatabaseService;
import gov.nasa.kepler.hibernate.dbservice.DatabaseServiceFactory;
import gov.nasa.kepler.hibernate.metrics.MetricType;
import gov.nasa.kepler.hibernate.metrics.MetricValue;
import gov.nasa.kepler.hibernate.metrics.MetricsCrud;
import gov.nasa.kepler.hibernate.services.Privilege;
import gov.nasa.kepler.ui.PipelineConsole;
import gov.nasa.spiffy.common.collect.Pair;

import java.util.Date;
import java.util.List;
import java.util.concurrent.Callable;

/**
 * @author Todd Klaus tklaus@arc.nasa.gov
 *
 */
public class MetricsLogCrudProxy extends CrudProxy{

    public MetricsLogCrudProxy() {
    }

    public List<MetricType> retrieveAllMetricTypes() {
        verifyPrivileges(Privilege.PIPELINE_MONITOR);
        List<MetricType> result = (List<MetricType>) PipelineConsole.crudProxyExecutor.executeSynchronous(new Callable<List<MetricType>>(){
            public List<MetricType> call() {
                DatabaseService databaseService = DatabaseServiceFactory.getInstance();
                MetricsCrud crud = new MetricsCrud(databaseService);

                databaseService.beginTransaction();
                
                List<MetricType> r = crud.retrieveAllMetricTypes();
                
                databaseService.commitTransaction();
                
                return r;
            }
        });
        return result;
    }

    public List<MetricValue> retrieveAllMetricValuesForType(final MetricType metricType, final Date start, final Date end) {
        verifyPrivileges(Privilege.PIPELINE_MONITOR);
        List<MetricValue> result = (List<MetricValue>) PipelineConsole.crudProxyExecutor.executeSynchronous(new Callable<List<MetricValue>>(){
            public List<MetricValue> call() {
                DatabaseService databaseService = DatabaseServiceFactory.getInstance();
                MetricsCrud crud = new MetricsCrud(databaseService);

                databaseService.beginTransaction();
                
                List<MetricValue> r = crud.retrieveAllMetricValuesForType(metricType, start, end);
                
                databaseService.commitTransaction();
                
                return r;
            }
        });
        return result;
    }

    public Pair<Date,Date> getTimestampRange(final MetricType metricType) {
        verifyPrivileges(Privilege.PIPELINE_MONITOR);
        Pair<Date,Date> result = (Pair<Date,Date>) PipelineConsole.crudProxyExecutor.executeSynchronous(new Callable<Pair<Date,Date>>(){
            public Pair<Date,Date> call() {
                DatabaseService databaseService = DatabaseServiceFactory.getInstance();
                MetricsCrud crud = new MetricsCrud(databaseService);

                databaseService.beginTransaction();
                
                Pair<Date,Date> r = crud.getTimestampRange(metricType);
                
                databaseService.commitTransaction();
                
                return r;
            }
        });
        return result;
    }
}
