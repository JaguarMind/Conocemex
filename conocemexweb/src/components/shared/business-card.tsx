import Link from 'next/link';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/core/utils/cn';

interface BusinessCardProps {
  id: string;
  name: string;
  category: string;
  imageUrl?: string;
  rating?: number;
  isOpen?: boolean;
  className?: string;
}

export function BusinessCard({
  id,
  name,
  category,
  imageUrl,
  rating,
  isOpen,
  className,
}: BusinessCardProps) {
  return (
    <Link href={`/business/${id}`}>
      <Card padding="none" className={cn('overflow-hidden group', className)}>
        <div className="aspect-video bg-surface-container-low overflow-hidden">
          {imageUrl && (
            <img
              src={imageUrl}
              alt={name}
              className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
            />
          )}
        </div>
        <div className="p-4">
          <div className="flex items-center justify-between gap-2">
            <h3 className="truncate text-sm font-display font-bold text-on-surface">
              {name}
            </h3>
            {isOpen !== undefined && (
              <Badge variant={isOpen ? 'success' : 'error'}>
                {isOpen ? 'Abierto' : 'Cerrado'}
              </Badge>
            )}
          </div>
          <div className="mt-1.5 flex items-center gap-2 text-xs text-on-surface-variant">
            <span>{category}</span>
            {rating !== undefined && <span>⭐ {rating.toFixed(1)}</span>}
          </div>
        </div>
      </Card>
    </Link>
  );
}
