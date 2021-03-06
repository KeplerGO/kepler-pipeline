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

package gov.nasa.kepler.tad.peer;

import static com.google.common.collect.Lists.newArrayList;
import gov.nasa.kepler.common.TargetManagementConstants;
import gov.nasa.kepler.hibernate.cm.PlannedTarget.TargetLabel;
import gov.nasa.kepler.hibernate.tad.Aperture;
import gov.nasa.kepler.hibernate.tad.ObservedTarget;
import gov.nasa.kepler.mc.tad.Offset;
import gov.nasa.kepler.mc.tad.OffsetList;
import gov.nasa.spiffy.common.persistable.Persistable;

import java.util.List;

import org.apache.commons.lang.ArrayUtils;

/**
 * Used to pass data to and from MATLAB.
 * 
 * @author Miles Cote
 */
public class ApertureStruct implements Persistable {

    private int keplerId;
    private boolean custom;
    private int badPixelCount;
    private int referenceRow;
    private int referenceColumn;

    private List<Offset> offsets = newArrayList();

    private String[] labels = ArrayUtils.EMPTY_STRING_ARRAY;

    public ApertureStruct() {
    }

    ApertureStruct(ObservedTarget observedTarget) {
        Aperture aperture = observedTarget.getAperture();

        keplerId = observedTarget.getKeplerId();
        custom = TargetManagementConstants.isCustomTarget(observedTarget.getKeplerId());
        referenceRow = aperture.getReferenceRow();
        referenceColumn = aperture.getReferenceColumn();
        badPixelCount = observedTarget.getBadPixelCount();
        offsets = OffsetList.toList(aperture.getOffsets());

        List<String> tadLabels = newArrayList();
        for (String label : observedTarget.getLabels()) {
            if (TargetLabel.isTadLabel(label)) {
                tadLabels.add(label);
            }
        }
        labels = tadLabels.toArray(new String[0]);
    }

    public int getBadPixelCount() {
        return badPixelCount;
    }

    public void setBadPixelCount(int badPixelCount) {
        this.badPixelCount = badPixelCount;
    }

    public int getKeplerId() {
        return keplerId;
    }

    public void setKeplerId(int keplerId) {
        this.keplerId = keplerId;
    }

    public List<Offset> getOffsets() {
        return offsets;
    }

    public void setOffsets(List<Offset> offsets) {
        this.offsets = offsets;
    }

    public int getReferenceColumn() {
        return referenceColumn;
    }

    public void setReferenceColumn(int referenceColumn) {
        this.referenceColumn = referenceColumn;
    }

    public int getReferenceRow() {
        return referenceRow;
    }

    public void setReferenceRow(int referenceRow) {
        this.referenceRow = referenceRow;
    }

    public String[] getLabels() {
        return labels;
    }

    public void setLabels(String[] labels) {
        this.labels = labels;
    }

    public boolean isCustom() {
        return custom;
    }

    public void setCustom(boolean custom) {
        this.custom = custom;
    }

}
