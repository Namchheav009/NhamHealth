package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "report_attachments")
public class ReportAttachment {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "attachment_id")
  private Integer attachmentId;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "report_id", nullable = false)
  private Report report;

  @Column(name = "image_url", nullable = false, length = 1000)
  private String imageUrl;

  @Column(name = "display_order", nullable = false)
  private Integer displayOrder;

  public Integer getAttachmentId() { return attachmentId; }
  public Report getReport() { return report; }
  public void setReport(Report value) { report = value; }
  public String getImageUrl() { return imageUrl; }
  public void setImageUrl(String value) { imageUrl = value; }
  public Integer getDisplayOrder() { return displayOrder; }
  public void setDisplayOrder(Integer value) { displayOrder = value; }
}
