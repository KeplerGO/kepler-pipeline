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

package gov.nasa.kepler.aft.seeder;

import gov.nasa.kepler.aft.descriptor.TestDataSetDescriptor;
import gov.nasa.kepler.dr.dispatch.DispatcherWrapper;
import gov.nasa.kepler.dr.dispatch.NotificationMessageHandler;
import gov.nasa.kepler.hibernate.dbservice.DatabaseService;
import gov.nasa.kepler.hibernate.dbservice.DatabaseServiceFactory;
import gov.nasa.kepler.hibernate.dr.LogCrud;
import gov.nasa.kepler.hibernate.dr.ReceiveLog;

import java.io.File;
import java.util.Collection;
import java.util.Date;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.filefilter.IOFileFilter;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public abstract class AbstractDispatcherSeeder extends DataStoreSeeder {
    private static final Log log = LogFactory.getLog(AbstractDispatcherSeeder.class);

    private String sourceDirectory;
    private IOFileFilter fileFilter;

    public AbstractDispatcherSeeder(TestDataSetDescriptor testDescriptor,
        String sourceDirectory) {

        super(testDescriptor);
        this.sourceDirectory = sourceDirectory;
    }

    public IOFileFilter getFileFilter() {
        return fileFilter;
    }

    public void setFileFilter(IOFileFilter fileFilter) {
        this.fileFilter = fileFilter;
    }

    public String getSourceDirectory() {
        File dir = new File(sourceDirectory);
        if (!dir.isDirectory()) {
            throw new IllegalStateException("SourceDirectory \""
                + sourceDirectory + "\" is not a directory.");
        }
        return sourceDirectory;
    }

    public void setSourceDirectory(String sourceDirectory) {
        this.sourceDirectory = sourceDirectory;
    }

    protected abstract DispatcherWrapper createDispatcher(
        NotificationMessageHandler handler);

    @Override
    public void seed() throws Exception {

        DispatcherWrapper dispatcher = createDispatcher(createHandler());

        log.info("Seeding from sourceDirectory = " + sourceDirectory);

        @SuppressWarnings("unchecked")
        Collection<File> files = FileUtils.listFiles(new File(
            getSourceDirectory()), getFileFilter(), null);
        if (files != null) {
            for (File file : files) {

                dispatcher.addFileName(file.getName());
            }
        }
        dispatcher.dispatch();
    }

    private NotificationMessageHandler createHandler() {
        DatabaseService databaseService = DatabaseServiceFactory.getInstance();
        ReceiveLog receiveLog = new ReceiveLog(new Date(), null, null);
        new LogCrud(databaseService).createReceiveLog(receiveLog);

        NotificationMessageHandler handler = new NotificationMessageHandler();
        handler.setReceiveLog(receiveLog);

        return handler;
    }

}
