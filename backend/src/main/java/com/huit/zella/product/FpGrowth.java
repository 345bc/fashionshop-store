package com.huit.zella.product;

import java.util.*;

/** FP-Growth over weighted conditional trees, with no fixed itemset-size limit. */
public final class FpGrowth {
    private FpGrowth() {}
    public record Itemset(List<Long> items, int count) {
        public Itemset { items=items.stream().sorted().toList(); }
    }
    public record Rule(List<Long> antecedent, List<Long> consequent, int count,
                       double support, double confidence, double lift) {}
    public record Model(int transactions, Map<Long,Integer> counts, List<Itemset> itemsets) {}
    private record Path(List<Long> items, int weight) {}
    private static final class Node {
        final Long item;
        final Node parent;
        int count;
        final Map<Long,Node> children=new HashMap<>();
        Node(Long item,Node parent) { this.item=item; this.parent=parent; }
    }
    private record Tree(Map<Long,Integer> counts, Map<Long,List<Node>> headers) {}

    public static Model mine(List<Set<Long>> baskets,int minimumCount) {
        if(minimumCount<1) throw new IllegalArgumentException("minimumCount must be positive");
        Map<Long,Integer> counts=new HashMap<>();
        baskets.forEach(b->b.forEach(id->counts.merge(id,1,Integer::sum)));
        var paths=baskets.stream().map(b->new Path(new ArrayList<>(b),1)).toList();
        List<Itemset> itemsets=new ArrayList<>();
        mine(tree(paths,minimumCount),List.of(),minimumCount,itemsets);
        itemsets.sort(Comparator.comparingInt((Itemset s)->s.items().size()).thenComparing(Itemset::items,FpGrowth::compareItems));
        return new Model(baskets.size(),Map.copyOf(counts),List.copyOf(itemsets));
    }

    private static Tree tree(List<Path> paths,int minimumCount) {
        Map<Long,Integer> counts=new HashMap<>();
        for(var path:paths) for(Long id:path.items()) counts.merge(id,path.weight(),Integer::sum);
        counts.entrySet().removeIf(e->e.getValue()<minimumCount);
        var order=Comparator.<Long>comparingInt(counts::get).reversed().thenComparingLong(Long::longValue);
        Node root=new Node(null,null);
        Map<Long,List<Node>> headers=new HashMap<>();
        for(var path:paths) {
            Node cursor=root;
            for(Long item:path.items().stream().filter(counts::containsKey).sorted(order).toList()) {
                Node child=cursor.children.get(item);
                if(child==null) {
                    child=new Node(item,cursor);
                    cursor.children.put(item,child);
                    headers.computeIfAbsent(item,k->new ArrayList<>()).add(child);
                }
                child.count+=path.weight();
                cursor=child;
            }
        }
        return new Tree(counts,headers);
    }

    private static void mine(Tree tree,List<Long> suffix,int minimumCount,List<Itemset> result) {
        var order=Comparator.<Long>comparingInt(tree.counts()::get).thenComparingLong(Long::longValue);
        for(Long item:tree.counts().keySet().stream().sorted(order).toList()) {
            List<Long> pattern=new ArrayList<>(suffix);
            pattern.add(item);
            result.add(new Itemset(pattern,tree.counts().get(item)));
            List<Path> conditional=new ArrayList<>();
            for(Node node:tree.headers().get(item)) {
                List<Long> prefix=new ArrayList<>();
                for(Node parent=node.parent;parent.item!=null;parent=parent.parent) prefix.add(parent.item);
                if(!prefix.isEmpty()) conditional.add(new Path(prefix,node.count));
            }
            if(!conditional.isEmpty()) mine(tree(conditional,minimumCount),pattern,minimumCount,result);
        }
    }

    /** Each singleton X in frequent L yields X -> L\X. */
    public static List<Rule> rules(Model model,double minConfidence) {
        if(!Double.isFinite(minConfidence) || minConfidence<0 || minConfidence>1) throw new IllegalArgumentException("Invalid minConfidence");
        if(model.transactions()==0) return List.of();
        Map<List<Long>,Integer> counts=new HashMap<>();
        model.itemsets().forEach(s->counts.put(s.items(),s.count()));
        List<Rule> result=new ArrayList<>();
        for(var itemset:model.itemsets()) if(itemset.items().size()>1) {
            for(Long item:itemset.items()) {
                List<Long> left=List.of(item);
                List<Long> right=itemset.items().stream().filter(id->!id.equals(item)).toList();
                double confidence=(double)itemset.count()/counts.get(left);
                if(confidence>=minConfidence) result.add(new Rule(left,right,itemset.count(),
                    (double)itemset.count()/model.transactions(),confidence,
                    confidence/((double)counts.get(right)/model.transactions())));
            }
        }
        result.sort(Comparator.comparingDouble(Rule::confidence).reversed()
            .thenComparing(Comparator.comparingDouble(Rule::lift).reversed())
            .thenComparing(Comparator.comparingInt(Rule::count).reversed())
            .thenComparing(Rule::antecedent,FpGrowth::compareItems).thenComparing(Rule::consequent,FpGrowth::compareItems));
        return List.copyOf(result);
    }

    private static int compareItems(List<Long> a,List<Long> b) {
        for(int i=0;i<Math.min(a.size(),b.size());i++) {
            int comparison=Long.compare(a.get(i),b.get(i));
            if(comparison!=0) return comparison;
        }
        return Integer.compare(a.size(),b.size());
    }
}
