import { useParams, Link } from 'react-router';
import { mockLoads, mockActivityEvents } from '../data/mockData';
import { StatusBadge } from '../components/StatusBadge';
import { Button } from '../components/ui/button';
import { Separator } from '../components/ui/separator';
import { 
  ArrowLeft, 
  FileText, 
  Calendar, 
  Truck, 
  User,
  Scale,
  Clock,
  AlertCircle,
  CheckCircle2,
  XCircle
} from 'lucide-react';
import { format } from 'date-fns';

export function LoadDetailPage() {
  const { loadId } = useParams();
  const load = mockLoads.find(l => l.id === loadId);
  const activities = mockActivityEvents.filter(e => e.loadId === loadId);

  if (!load) {
    return (
      <div className="py-12 px-6 text-center">
        <h2 className="text-xl mb-2">Weigh tag not found</h2>
        <p className="text-muted-foreground mb-4">The weigh tag ID you requested does not exist.</p>
        <Link to="/">
          <Button variant="outline">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to weigh tags
          </Button>
        </Link>
      </div>
    );
  }

  const senderTag = load.senderTag;
  const receiverTag = load.receiverTag;
  
  const weightDelta = senderTag && receiverTag
    ? receiverTag.netWeight - senderTag.netWeight
    : null;
  
  const weightVariance = senderTag && receiverTag && senderTag.netWeight > 0
    ? (weightDelta! / senderTag.netWeight * 100)
    : null;

  const moistureDelta = senderTag?.moisture && receiverTag?.moisture
    ? receiverTag.moisture - senderTag.moisture
    : null;

  return (
    <div className="py-4 px-6">
      {/* Breadcrumb */}
      <div className="mb-3">
        <Link to="/" className="text-sm text-muted-foreground hover:text-foreground inline-flex items-center">
          <ArrowLeft className="h-3 w-3 mr-1" />
          Back to weigh tags
        </Link>
      </div>

      {/* Page Header with Title and Actions Ribbon */}
      <div className="bg-white border rounded mb-4">
        <div className="px-6 py-4 border-b">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <h1 className="text-xl font-mono">{load.id}</h1>
              <StatusBadge status={load.status} />
            </div>
            <div className="flex gap-2">
              <Button variant="outline" size="sm">
                <FileText className="h-4 w-4 mr-1.5" />
                View PDF
              </Button>
              <Button variant="outline" size="sm">
                <Clock className="h-4 w-4 mr-1.5" />
                Activity
              </Button>
              {load.status === 'review' && (
                <>
                  <Button variant="outline" size="sm">Accept</Button>
                  <Button variant="default" size="sm">Dispute</Button>
                </>
              )}
            </div>
          </div>
        </div>

        {/* General Information Section */}
        <div className="px-6 py-4">
          <div className="grid grid-cols-4 gap-x-6 gap-y-3 text-sm">
            <div>
              <div className="text-xs text-muted-foreground mb-0.5">BOL Number</div>
              <div className="font-medium font-mono">{load.bolNumber}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-0.5">Ship Date</div>
              <div className="font-mono tabular-nums">{format(new Date(load.shipDate), 'MMM d, yyyy h:mm a')}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-0.5">Truck Number</div>
              <div className="font-medium">{load.truckNumber}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-0.5">Driver</div>
              <div>{load.driverName}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-0.5">Commodity</div>
              <div className="font-medium">{load.commodity}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-0.5">Sender</div>
              <div>{load.sender}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-0.5">Receiver</div>
              <div>{load.receiver}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Alert for review or dispute */}
      {(load.status === 'review' || load.status === 'disputed') && (
        <div className={`border rounded-lg p-4 mb-6 ${
          load.status === 'disputed' ? 'bg-[#dc2626]/5 border-[#dc2626]/20' : 'bg-[#b45309]/5 border-[#b45309]/20'
        }`}>
          <div className="flex items-start gap-3">
            <AlertCircle className={`h-5 w-5 mt-0.5 ${
              load.status === 'disputed' ? 'text-[#dc2626]' : 'text-[#b45309]'
            }`} />
            <div className="flex-1">
              <h3 className="font-medium mb-1">
                {load.status === 'disputed' ? 'Dispute filed' : 'Review needed'}
              </h3>
              <p className="text-sm text-muted-foreground">
                {load.reviewReason}
              </p>
              {load.disputeNotes && (
                <p className="text-sm mt-2 font-medium">{load.disputeNotes}</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Weigh Tag Comparison Table */}
      <div className="bg-white border rounded overflow-hidden">
        <div className="bg-secondary/50 px-6 py-2.5 border-b">
          <h2 className="font-medium text-sm">Weigh Tag Comparison</h2>
        </div>

        <table className="w-full text-sm">
          <thead>
            <tr className="border-b bg-secondary/30">
              <th className="text-left px-6 py-2 font-medium text-xs text-muted-foreground w-[200px]">Field</th>
              <th className="text-right px-6 py-2 font-medium text-xs text-muted-foreground">
                Sender
                {senderTag ? (
                  <CheckCircle2 className="h-3.5 w-3.5 text-[#059669] inline ml-2" />
                ) : (
                  <XCircle className="h-3.5 w-3.5 text-muted-foreground inline ml-2" />
                )}
              </th>
              <th className="text-center px-6 py-2 font-medium text-xs text-muted-foreground bg-secondary/50">Delta (Δ)</th>
              <th className="text-right px-6 py-2 font-medium text-xs text-muted-foreground">
                Receiver
                {receiverTag ? (
                  <CheckCircle2 className="h-3.5 w-3.5 text-[#059669] inline ml-2" />
                ) : (
                  <XCircle className="h-3.5 w-3.5 text-muted-foreground inline ml-2" />
                )}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr className="border-b bg-[#fefcf8]">
              <td className="px-6 py-2.5 text-muted-foreground">Gross Weight (lb)</td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                {senderTag ? senderTag.grossWeight.toLocaleString() : '—'}
              </td>
              <td className="px-6 py-2.5 text-center bg-secondary/30"></td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                {receiverTag ? receiverTag.grossWeight.toLocaleString() : '—'}
              </td>
            </tr>
            <tr className="border-b">
              <td className="px-6 py-2.5 text-muted-foreground">Tare Weight (lb)</td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                {senderTag ? senderTag.tareWeight.toLocaleString() : '—'}
              </td>
              <td className="px-6 py-2.5 text-center bg-secondary/30"></td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                {receiverTag ? receiverTag.tareWeight.toLocaleString() : '—'}
              </td>
            </tr>
            <tr className="border-b bg-[#fefcf8] font-medium">
              <td className="px-6 py-2.5 text-foreground">Net Weight (lb)</td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                {senderTag ? senderTag.netWeight.toLocaleString() : '—'}
              </td>
              <td className="px-6 py-2.5 text-center bg-secondary/30">
                {senderTag && receiverTag ? (
                  <div>
                    <div className={`font-mono tabular-nums ${
                      Math.abs(weightVariance!) > 0.5 ? 'text-[#b45309]' : 'text-[#059669]'
                    }`}>
                      {weightDelta! > 0 ? '+' : ''}{weightDelta!.toLocaleString()}
                    </div>
                    <div className={`text-xs font-mono tabular-nums ${
                      Math.abs(weightVariance!) > 0.5 ? 'text-[#b45309]' : 'text-muted-foreground'
                    }`}>
                      ({weightVariance! > 0 ? '+' : ''}{weightVariance!.toFixed(2)}%)
                    </div>
                  </div>
                ) : '—'}
              </td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                {receiverTag ? receiverTag.netWeight.toLocaleString() : '—'}
              </td>
            </tr>
            {(senderTag?.moisture || receiverTag?.moisture) && (
              <tr className="border-b">
                <td className="px-6 py-2.5 text-muted-foreground">Moisture (%)</td>
                <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                  {senderTag?.moisture ? `${senderTag.moisture.toFixed(1)}%` : '—'}
                </td>
                <td className="px-6 py-2.5 text-center bg-secondary/30 font-mono tabular-nums">
                  {moistureDelta !== null ? `${moistureDelta > 0 ? '+' : ''}${moistureDelta.toFixed(1)}%` : '—'}
                </td>
                <td className="px-6 py-2.5 text-right font-mono tabular-nums">
                  {receiverTag?.moisture ? `${receiverTag.moisture.toFixed(1)}%` : '—'}
                </td>
              </tr>
            )}
            <tr className="border-b bg-[#fefcf8]">
              <td className="px-6 py-2.5 text-muted-foreground">Timestamp</td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums text-xs">
                {senderTag ? format(new Date(senderTag.timestamp), 'MMM d, yyyy h:mm a') : '—'}
              </td>
              <td className="px-6 py-2.5 text-center bg-secondary/30"></td>
              <td className="px-6 py-2.5 text-right font-mono tabular-nums text-xs">
                {receiverTag ? format(new Date(receiverTag.timestamp), 'MMM d, yyyy h:mm a') : '—'}
              </td>
            </tr>
            <tr className="border-b">
              <td className="px-6 py-2.5 text-muted-foreground">Weighed By</td>
              <td className="px-6 py-2.5 text-right">
                {senderTag ? senderTag.weighedBy : '—'}
              </td>
              <td className="px-6 py-2.5 text-center bg-secondary/30"></td>
              <td className="px-6 py-2.5 text-right">
                {receiverTag ? receiverTag.weighedBy : '—'}
              </td>
            </tr>
            <tr className="border-b bg-[#fefcf8]">
              <td className="px-6 py-2.5 text-muted-foreground">Scale ID</td>
              <td className="px-6 py-2.5 text-right font-mono">
                {senderTag ? senderTag.scaleId : '—'}
              </td>
              <td className="px-6 py-2.5 text-center bg-secondary/30"></td>
              <td className="px-6 py-2.5 text-right font-mono">
                {receiverTag ? receiverTag.scaleId : '—'}
              </td>
            </tr>
            {(senderTag?.notes || receiverTag?.notes) && (
              <tr className="border-b">
                <td className="px-6 py-2.5 text-muted-foreground align-top">Notes</td>
                <td className="px-6 py-2.5 text-right align-top">
                  {senderTag?.notes || '—'}
                </td>
                <td className="px-6 py-2.5 text-center bg-secondary/30"></td>
                <td className="px-6 py-2.5 text-right align-top">
                  {receiverTag?.notes || '—'}
                </td>
              </tr>
            )}
          </tbody>
        </table>

        {/* Variance Summary Footer */}
        {senderTag && receiverTag && (
          <div className="border-t bg-secondary/20 px-6 py-3">
            <div className="flex items-center justify-between">
              <div className="text-sm font-medium">Variance Status:</div>
              <div>
                {Math.abs(weightVariance!) <= 0.5 ? (
                  <div className="inline-flex items-center gap-2 text-sm text-[#059669] font-medium">
                    <CheckCircle2 className="h-4 w-4" />
                    <span>Within tolerance (±0.5%)</span>
                  </div>
                ) : (
                  <div className="inline-flex items-center gap-2 text-sm text-[#b45309] font-medium">
                    <AlertCircle className="h-4 w-4" />
                    <span>Exceeds tolerance (±0.5%)</span>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Activity Log */}
      {activities.length > 0 && (
        <div className="bg-white border rounded mt-4">
          <div className="bg-secondary/50 px-6 py-2.5 border-b">
            <h2 className="font-medium text-sm">Activity Log</h2>
          </div>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-secondary/30">
                <th className="text-left px-6 py-2 font-medium text-xs text-muted-foreground">Timestamp</th>
                <th className="text-left px-6 py-2 font-medium text-xs text-muted-foreground">Action</th>
                <th className="text-left px-6 py-2 font-medium text-xs text-muted-foreground">Details</th>
                <th className="text-left px-6 py-2 font-medium text-xs text-muted-foreground">Actor</th>
              </tr>
            </thead>
            <tbody>
              {activities.map((event, index) => (
                <tr key={event.id} className={`border-b ${index % 2 === 0 ? 'bg-[#fefcf8]' : ''}`}>
                  <td className="px-6 py-2.5 font-mono tabular-nums text-xs whitespace-nowrap">
                    {format(new Date(event.timestamp), 'MMM d, yyyy h:mm a')}
                  </td>
                  <td className="px-6 py-2.5 font-medium">{event.action}</td>
                  <td className="px-6 py-2.5 text-muted-foreground">{event.details}</td>
                  <td className="px-6 py-2.5">{event.actor}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
