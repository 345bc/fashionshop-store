package com.huit.zella.product;

import org.junit.jupiter.api.Test;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

class FpGrowthTest {
    @Test void allItemsetSizesMatchBruteForceAcrossRandomBaskets() {
        var random=new Random(48);
        for(int run=0;run<100;run++) {
            List<Set<Long>> baskets=new ArrayList<>();
            for(int i=0;i<30;i++) {
                Set<Long> basket=new HashSet<>();
                for(long id=1;id<=8;id++) if(random.nextBoolean()) basket.add(id);
                baskets.add(basket);
            }
            int minimum=1+random.nextInt(10);
            var model=FpGrowth.mine(baskets,minimum);
            Map<List<Long>,Integer> expected=new HashMap<>();
            for(int mask=1;mask<(1<<8);mask++) {
                List<Long> items=new ArrayList<>();
                for(int i=0;i<8;i++) if((mask&(1<<i))!=0) items.add((long)i+1);
                int count=(int)baskets.stream().filter(b->b.containsAll(items)).count();
                if(count>=minimum) expected.put(items,count);
            }
            Map<List<Long>,Integer> actual=new HashMap<>();
            model.itemsets().forEach(s->assertNull(actual.put(s.items(),s.count()),"Duplicate itemset"));
            assertEquals(expected,actual);
            assertEquals(baskets.size(),model.transactions());
        }
    }
    @Test void generatesOnlySingletonAntecedentsWithMultiProductConsequents() {
        var model=FpGrowth.mine(List.of(Set.of(1L,2L,3L,4L),Set.of(1L,2L,3L,4L),Set.of(9L)),1);
        var rules=FpGrowth.rules(model,0);
        // Four-product itemset yields four singleton-left rules.
        var four=rules.stream().filter(r->r.antecedent().size()+r.consequent().size()==4).toList();
        assertEquals(4,four.size());
        assertEquals(28,rules.size());
        var rule=rules.stream().filter(r->r.antecedent().equals(List.of(1L)) && r.consequent().equals(List.of(2L,3L,4L))).findFirst().orElseThrow();
        assertEquals(2.0/3,rule.support());
        assertEquals(1,rule.confidence());
        assertEquals(1.5,rule.lift());
        for(var r:rules) {
            assertEquals(1,r.antecedent().size()); assertFalse(r.consequent().isEmpty());
            assertTrue(Collections.disjoint(r.antecedent(),r.consequent()));
        }
    }
    @Test void confidenceIsDirectionalAndInclusiveAtThreshold() {
        var model=FpGrowth.mine(List.of(Set.of(1L,2L),Set.of(1L),Set.of(3L)),1);
        var rules=FpGrowth.rules(model,0.5);
        assertEquals(2,rules.size());
        assertEquals(0.5,rules.stream().filter(r->r.antecedent().equals(List.of(1L))).findFirst().orElseThrow().confidence());
        assertEquals(1,FpGrowth.rules(model,0.51).size());
    }
    @Test void handlesSingletonsEmptyAndInfrequentData() {
        assertTrue(FpGrowth.mine(List.of(),1).itemsets().isEmpty());
        var model=FpGrowth.mine(List.of(Set.of(1L,2L),Set.of(1L)),2);
        assertEquals(List.of(new FpGrowth.Itemset(List.of(1L),2)),model.itemsets());
        assertTrue(FpGrowth.rules(model,0).isEmpty());
        assertThrows(IllegalArgumentException.class,()->FpGrowth.mine(List.of(),0));
    }
}
