export type LoadStatus = 
  | 'draft'
  | 'pending'
  | 'matched'
  | 'review'
  | 'disputed'
  | 'resolved'
  | 'invoiced';

export type Party = 'sender' | 'receiver';

export interface WeighTag {
  party: Party;
  loadNumber: string;
  grossWeight: number;
  tareWeight: number;
  netWeight: number;
  moisture?: number;
  timestamp: string;
  weighedBy: string;
  scaleId: string;
  notes?: string;
}

export interface Load {
  id: string;
  bolNumber: string;
  commodity: string;
  sender: string;
  receiver: string;
  truckNumber: string;
  driverName: string;
  shipDate: string;
  status: LoadStatus;
  senderTag?: WeighTag;
  receiverTag?: WeighTag;
  reviewReason?: string;
  disputeNotes?: string;
  resolutionNotes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ActivityEvent {
  id: string;
  loadId: string;
  timestamp: string;
  actor: string;
  action: string;
  details: string;
  changes?: Record<string, any>;
}
