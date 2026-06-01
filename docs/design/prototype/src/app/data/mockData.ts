import { Load, ActivityEvent } from '../types';

export const mockLoads: Load[] = [
  {
    id: 'WT-2026-0527-001',
    bolNumber: 'BOL-45892',
    commodity: 'Hard Red Winter Wheat',
    sender: 'Anderson Farms',
    receiver: 'Heartland Grain Co.',
    truckNumber: 'TR-4521',
    driverName: 'Mike Patterson',
    shipDate: '2026-05-27T08:15:00-05:00',
    status: 'matched',
    createdAt: '2026-05-27T08:15:00-05:00',
    updatedAt: '2026-05-27T14:22:00-05:00',
    senderTag: {
      party: 'sender',
      loadNumber: 'WT-2026-0527-001',
      grossWeight: 82450,
      tareWeight: 32100,
      netWeight: 50350,
      moisture: 12.3,
      timestamp: '2026-05-27T08:15:00-05:00',
      weighedBy: 'Sarah Chen',
      scaleId: 'SCALE-AF-01',
      notes: 'Standard load, good condition'
    },
    receiverTag: {
      party: 'receiver',
      loadNumber: 'WT-2026-0527-001',
      grossWeight: 82420,
      tareWeight: 32100,
      netWeight: 50320,
      moisture: 12.4,
      timestamp: '2026-05-27T14:22:00-05:00',
      weighedBy: 'Tom Richards',
      scaleId: 'SCALE-HG-02'
    }
  },
  {
    id: 'WT-2026-0527-002',
    bolNumber: 'BOL-45893',
    commodity: 'Soybeans',
    sender: 'Prairie View Co-op',
    receiver: 'Midwest Processors',
    truckNumber: 'TR-8834',
    driverName: 'Jennifer Martinez',
    shipDate: '2026-05-27T09:30:00-05:00',
    status: 'review',
    createdAt: '2026-05-27T09:30:00-05:00',
    updatedAt: '2026-05-27T15:45:00-05:00',
    reviewReason: 'Net weight variance exceeds 0.5% threshold',
    senderTag: {
      party: 'sender',
      loadNumber: 'WT-2026-0527-002',
      grossWeight: 78920,
      tareWeight: 30200,
      netWeight: 48720,
      moisture: 13.1,
      timestamp: '2026-05-27T09:30:00-05:00',
      weighedBy: 'David Park',
      scaleId: 'SCALE-PV-01'
    },
    receiverTag: {
      party: 'receiver',
      loadNumber: 'WT-2026-0527-002',
      grossWeight: 78560,
      tareWeight: 30200,
      netWeight: 48360,
      moisture: 13.3,
      timestamp: '2026-05-27T15:45:00-05:00',
      weighedBy: 'Lisa Wong',
      scaleId: 'SCALE-MP-03',
      notes: 'Some spillage observed during unload'
    }
  },
  {
    id: 'WT-2026-0527-003',
    bolNumber: 'BOL-45894',
    commodity: 'Yellow Corn',
    sender: 'Thompson Grain',
    receiver: 'Riverbank Feed Mill',
    truckNumber: 'TR-2293',
    driverName: 'Robert Johnson',
    shipDate: '2026-05-27T10:45:00-05:00',
    status: 'pending',
    createdAt: '2026-05-27T10:45:00-05:00',
    updatedAt: '2026-05-27T10:45:00-05:00',
    senderTag: {
      party: 'sender',
      loadNumber: 'WT-2026-0527-003',
      grossWeight: 85200,
      tareWeight: 33500,
      netWeight: 51700,
      moisture: 14.2,
      timestamp: '2026-05-27T10:45:00-05:00',
      weighedBy: 'Maria Garcia',
      scaleId: 'SCALE-TG-01'
    }
  },
  {
    id: 'WT-2026-0526-089',
    bolNumber: 'BOL-45891',
    commodity: 'Hard Red Winter Wheat',
    sender: 'Golden Plains LLC',
    receiver: 'Central Grain Terminal',
    truckNumber: 'TR-5567',
    driverName: 'James Wilson',
    shipDate: '2026-05-26T16:20:00-05:00',
    status: 'resolved',
    createdAt: '2026-05-26T16:20:00-05:00',
    updatedAt: '2026-05-27T09:15:00-05:00',
    reviewReason: 'Moisture content variance',
    resolutionNotes: 'Average of both measurements accepted per contract clause 7.2',
    senderTag: {
      party: 'sender',
      loadNumber: 'WT-2026-0526-089',
      grossWeight: 81200,
      tareWeight: 31800,
      netWeight: 49400,
      moisture: 11.8,
      timestamp: '2026-05-26T16:20:00-05:00',
      weighedBy: 'Kevin Brown',
      scaleId: 'SCALE-GP-02'
    },
    receiverTag: {
      party: 'receiver',
      loadNumber: 'WT-2026-0526-089',
      grossWeight: 81180,
      tareWeight: 31800,
      netWeight: 49380,
      moisture: 12.5,
      timestamp: '2026-05-27T08:30:00-05:00',
      weighedBy: 'Amanda Lee',
      scaleId: 'SCALE-CG-01',
      notes: 'Moisture retest performed - 12.5% confirmed'
    }
  },
  {
    id: 'WT-2026-0526-088',
    bolNumber: 'BOL-45885',
    commodity: 'Soybeans',
    sender: 'Valley Harvest Inc.',
    receiver: 'Export Terminal 5',
    truckNumber: 'TR-9901',
    driverName: 'Patricia Davis',
    shipDate: '2026-05-26T14:00:00-05:00',
    status: 'invoiced',
    createdAt: '2026-05-26T14:00:00-05:00',
    updatedAt: '2026-05-27T08:00:00-05:00',
    senderTag: {
      party: 'sender',
      loadNumber: 'WT-2026-0526-088',
      grossWeight: 79500,
      tareWeight: 30900,
      netWeight: 48600,
      moisture: 12.9,
      timestamp: '2026-05-26T14:00:00-05:00',
      weighedBy: 'Chris Anderson',
      scaleId: 'SCALE-VH-01'
    },
    receiverTag: {
      party: 'receiver',
      loadNumber: 'WT-2026-0526-088',
      grossWeight: 79480,
      tareWeight: 30900,
      netWeight: 48580,
      moisture: 13.0,
      timestamp: '2026-05-26T19:25:00-05:00',
      weighedBy: 'Daniel Kim',
      scaleId: 'SCALE-ET5-02'
    }
  },
  {
    id: 'WT-2026-0527-004',
    bolNumber: 'BOL-45895',
    commodity: 'Milo (Grain Sorghum)',
    sender: 'Redstone Farms',
    receiver: 'Cattlemen\'s Feed Supply',
    truckNumber: 'TR-3312',
    driverName: 'Susan Thompson',
    shipDate: '2026-05-27T11:20:00-05:00',
    status: 'disputed',
    createdAt: '2026-05-27T11:20:00-05:00',
    updatedAt: '2026-05-27T16:10:00-05:00',
    reviewReason: 'Significant weight variance - 2.1%',
    disputeNotes: 'Sender disputes receiver measurement - requesting third-party verification',
    senderTag: {
      party: 'sender',
      loadNumber: 'WT-2026-0527-004',
      grossWeight: 76800,
      tareWeight: 29500,
      netWeight: 47300,
      moisture: 13.5,
      timestamp: '2026-05-27T11:20:00-05:00',
      weighedBy: 'Rachel Green',
      scaleId: 'SCALE-RF-01',
      notes: 'Scale certified 05/15/2026'
    },
    receiverTag: {
      party: 'receiver',
      loadNumber: 'WT-2026-0527-004',
      grossWeight: 75800,
      tareWeight: 29500,
      netWeight: 46300,
      moisture: 13.8,
      timestamp: '2026-05-27T16:10:00-05:00',
      weighedBy: 'Brian Foster',
      scaleId: 'SCALE-CF-01',
      notes: 'Scale recalibrated this morning - readings verified'
    }
  },
  {
    id: 'WT-2026-0527-005',
    bolNumber: 'BOL-45896',
    commodity: 'Hard Red Winter Wheat',
    sender: 'Clearwater Grain',
    receiver: 'Millstone Flour Co.',
    truckNumber: 'TR-6645',
    driverName: 'Carlos Rodriguez',
    shipDate: '2026-05-27T13:00:00-05:00',
    status: 'matched',
    createdAt: '2026-05-27T13:00:00-05:00',
    updatedAt: '2026-05-27T17:30:00-05:00',
    senderTag: {
      party: 'sender',
      loadNumber: 'WT-2026-0527-005',
      grossWeight: 83100,
      tareWeight: 32400,
      netWeight: 50700,
      moisture: 12.0,
      timestamp: '2026-05-27T13:00:00-05:00',
      weighedBy: 'Emily White',
      scaleId: 'SCALE-CW-02'
    },
    receiverTag: {
      party: 'receiver',
      loadNumber: 'WT-2026-0527-005',
      grossWeight: 83090,
      tareWeight: 32400,
      netWeight: 50690,
      moisture: 12.1,
      timestamp: '2026-05-27T17:30:00-05:00',
      weighedBy: 'George Miller',
      scaleId: 'SCALE-MF-01'
    }
  }
];

export const mockActivityEvents: ActivityEvent[] = [
  {
    id: 'EVT-001',
    loadId: 'WT-2026-0527-001',
    timestamp: '2026-05-27T08:15:00-05:00',
    actor: 'Sarah Chen (Anderson Farms)',
    action: 'Created load',
    details: 'Sender weigh tag created'
  },
  {
    id: 'EVT-002',
    loadId: 'WT-2026-0527-001',
    timestamp: '2026-05-27T14:22:00-05:00',
    actor: 'Tom Richards (Heartland Grain Co.)',
    action: 'Added receiver tag',
    details: 'Receiver weigh tag recorded'
  },
  {
    id: 'EVT-003',
    loadId: 'WT-2026-0527-001',
    timestamp: '2026-05-27T14:23:00-05:00',
    actor: 'System',
    action: 'Auto-matched',
    details: 'Tags matched - variance 0.06% (within 0.5% threshold)'
  },
  {
    id: 'EVT-004',
    loadId: 'WT-2026-0527-002',
    timestamp: '2026-05-27T09:30:00-05:00',
    actor: 'David Park (Prairie View Co-op)',
    action: 'Created load',
    details: 'Sender weigh tag created'
  },
  {
    id: 'EVT-005',
    loadId: 'WT-2026-0527-002',
    timestamp: '2026-05-27T15:45:00-05:00',
    actor: 'Lisa Wong (Midwest Processors)',
    action: 'Added receiver tag',
    details: 'Receiver weigh tag recorded with notes'
  },
  {
    id: 'EVT-006',
    loadId: 'WT-2026-0527-002',
    timestamp: '2026-05-27T15:46:00-05:00',
    actor: 'System',
    action: 'Flagged for review',
    details: 'Net weight variance 0.74% exceeds threshold - requires review'
  },
  {
    id: 'EVT-007',
    loadId: 'WT-2026-0527-004',
    timestamp: '2026-05-27T16:11:00-05:00',
    actor: 'Rachel Green (Redstone Farms)',
    action: 'Disputed',
    details: 'Sender disputes receiver measurement - requesting verification'
  }
];
