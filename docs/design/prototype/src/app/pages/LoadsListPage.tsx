import { useState } from 'react';
import { Link } from 'react-router';
import { mockLoads } from '../data/mockData';
import { LoadStatus } from '../types';
import { StatusBadge } from '../components/StatusBadge';
import { Button } from '../components/ui/button';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '../components/ui/table';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../components/ui/select';
import { Filter, ArrowUpDown } from 'lucide-react';
import { format } from 'date-fns';

// User-facing language: "weigh tag" everywhere visible.
// The internal entity is still called Load (the canonical joined record
// for a physical truckload, joining one or two Tags). That naming stays
// in the code; only the UI surfaces use the user term.
export function LoadsListPage() {
  const [statusFilter, setStatusFilter] = useState<LoadStatus | 'all'>('all');
  
  const filteredLoads = statusFilter === 'all' 
    ? mockLoads 
    : mockLoads.filter(load => load.status === statusFilter);
  
  const stats = {
    pending: mockLoads.filter(l => l.status === 'pending').length,
    review: mockLoads.filter(l => l.status === 'review').length,
    disputed: mockLoads.filter(l => l.status === 'disputed').length,
    matched: mockLoads.filter(l => l.status === 'matched').length,
  };

  return (
    <div className="py-6 px-6">
      {/* Page Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-1">Weigh tags</h1>
        <p className="text-sm text-muted-foreground">
          Reconciliation dashboard for all commodity shipments
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <div className="bg-white border rounded-lg p-4">
          <div className="text-xs text-muted-foreground mb-1">Pending Receiver</div>
          <div className="text-2xl font-medium tabular-nums">{stats.pending}</div>
        </div>
        <div className="bg-white border rounded-lg p-4">
          <div className="text-xs text-muted-foreground mb-1">Needs review</div>
          <div className="text-2xl font-medium tabular-nums text-[#b45309]">{stats.review}</div>
        </div>
        <div className="bg-white border rounded-lg p-4">
          <div className="text-xs text-muted-foreground mb-1">Disputed</div>
          <div className="text-2xl font-medium tabular-nums text-[#dc2626]">{stats.disputed}</div>
        </div>
        <div className="bg-white border rounded-lg p-4">
          <div className="text-xs text-muted-foreground mb-1">Matched Today</div>
          <div className="text-2xl font-medium tabular-nums text-[#059669]">{stats.matched}</div>
        </div>
      </div>

      {/* Table Controls */}
      <div className="bg-white border rounded-lg">
        <div className="px-4 py-3 border-b flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Filter className="h-4 w-4 text-muted-foreground" />
            <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as LoadStatus | 'all')}>
              <SelectTrigger className="w-[200px]">
                <SelectValue placeholder="Filter by status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="pending">Pending Receiver</SelectItem>
                <SelectItem value="matched">Matched</SelectItem>
                <SelectItem value="review">Review</SelectItem>
                <SelectItem value="disputed">Disputed</SelectItem>
                <SelectItem value="resolved">Resolved</SelectItem>
                <SelectItem value="invoiced">Invoiced</SelectItem>
              </SelectContent>
            </Select>
            
            <div className="text-sm text-muted-foreground">
              {filteredLoads.length} {filteredLoads.length === 1 ? 'weigh tag' : 'weigh tags'}
            </div>
          </div>
          
          <Button variant="ghost" size="sm">
            <ArrowUpDown className="h-4 w-4 mr-2" />
            Sort
          </Button>
        </div>

        {/* Weigh tags table */}
        <Table>
          <TableHeader>
            <TableRow className="bg-secondary/50">
              <TableHead className="w-[140px]">Tag ID</TableHead>
              <TableHead className="w-[120px]">BOL Number</TableHead>
              <TableHead className="w-[110px]">Ship Date</TableHead>
              <TableHead>Commodity</TableHead>
              <TableHead>Sender</TableHead>
              <TableHead>Receiver</TableHead>
              <TableHead className="w-[100px]">Truck</TableHead>
              <TableHead className="text-right w-[110px]">Sender Net (lb)</TableHead>
              <TableHead className="text-right w-[110px]">Receiver Net (lb)</TableHead>
              <TableHead className="text-right w-[80px]">Δ (%)</TableHead>
              <TableHead className="w-[140px]">Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredLoads.map((load) => {
              const variance = load.senderTag && load.receiverTag
                ? ((load.receiverTag.netWeight - load.senderTag.netWeight) / load.senderTag.netWeight * 100)
                : null;
              
              return (
                <TableRow key={load.id} className="hover:bg-secondary/30">
                  <TableCell className="font-mono text-sm">
                    <Link to={`/weigh-tags/${load.id}`} className="text-primary hover:underline">
                      {load.id}
                    </Link>
                  </TableCell>
                  <TableCell className="font-mono text-sm">{load.bolNumber}</TableCell>
                  <TableCell className="text-sm tabular-nums">
                    {format(new Date(load.shipDate), 'MM/dd/yyyy')}
                  </TableCell>
                  <TableCell className="text-sm">{load.commodity}</TableCell>
                  <TableCell className="text-sm">{load.sender}</TableCell>
                  <TableCell className="text-sm">{load.receiver}</TableCell>
                  <TableCell className="text-sm font-mono">{load.truckNumber}</TableCell>
                  <TableCell className="text-right tabular-nums text-sm">
                    {load.senderTag ? load.senderTag.netWeight.toLocaleString() : '—'}
                  </TableCell>
                  <TableCell className="text-right tabular-nums text-sm">
                    {load.receiverTag ? load.receiverTag.netWeight.toLocaleString() : '—'}
                  </TableCell>
                  <TableCell className="text-right tabular-nums text-sm">
                    {variance !== null ? (
                      <span className={variance > 0.5 || variance < -0.5 ? 'text-[#b45309]' : ''}>
                        {variance > 0 ? '+' : ''}{variance.toFixed(2)}%
                      </span>
                    ) : '—'}
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={load.status} />
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
