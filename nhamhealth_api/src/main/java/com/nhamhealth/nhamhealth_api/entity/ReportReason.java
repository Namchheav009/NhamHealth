package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "report_reasons")
public class ReportReason {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "report_reason_id")
    private Integer reportReasonId;

    @Column(name = "reason_name", nullable = false, unique = true, length = 100)
    private String reasonName;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    public ReportReason() {
    }

    public Integer getReportReasonId() {
        return reportReasonId;
    }

    public String getReasonName() {
        return reasonName;
    }

    public void setReasonName(String reasonName) {
        this.reasonName = reasonName;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }
}
