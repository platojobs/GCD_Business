//
//  ViewController.m
//  GCDPJSt
//
//  Created by PlatoJobs on 2019/2/21.
//  Copyright © 2019 David. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
  //  [self pjGlobalQueueAndMainQueue];
    
  //  [self pjDispatch_apply];
    
  //  [self pjDispatch_suspendAnddispatch_resume];
    [self pj_Semaphore];
    
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark===Serial Diapatch Queue 串行队列
/*
 当任务相互依赖，具有明显的先后顺序的时候，使用串行队列是一个不错的选择创建一个串行队列
 */
-(void)testSerialDiapatchQueue {
    
    dispatch_queue_t serialDispatchQueue=dispatch_queue_create("com.PlatoJobs.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(serialDispatchQueue, ^{
        NSLog(@"1");
    });
    
    dispatch_async(serialDispatchQueue, ^{
        sleep(2);
        NSLog(@"2");
    });
    
    dispatch_async(serialDispatchQueue, ^{
        sleep(1);
        NSLog(@"3");
    });
    
    //执行结果：串行输出，相互彼此依赖，串行执行1->2->3
}

#pragma mark==Concurrent Diapatch Queue 并发队列

-(void)pjtestConcurrentDiapatchQueue{
    
    dispatch_queue_t concurrentDispatchQueue=dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrentDispatchQueue, ^{
        NSLog(@"1");
    });
    
    dispatch_async(concurrentDispatchQueue, ^{
        NSLog(@"2");
    });
    
    dispatch_async(concurrentDispatchQueue, ^{
        NSLog(@"3");
    });
    
    //在不同的i线程中执行，相互不依赖，不阻塞
}

#pragma mark==Global Queue & Main Queue
//Global Queue其实就是系统创建的Concurrent Diapatch Queue
//Main Queue 其实就是系统创建的位于主线程的Serial Diapatch Queue
// 通常情况我们会把这2个队列放在一起使用，也是我们最常用的开异步线程-执行异步任务-回主线程的一种方式
-(void)pjGlobalQueueAndMainQueue{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"异步线程");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"异步主线程");
        });
    });
   /*
    dispatch_get_global_queue存在优先级，没错，他一共有4个优先级:
    
    #define DISPATCH_QUEUE_PRIORITY_HIGH 2
    #define DISPATCH_QUEUE_PRIORITY_DEFAULT 0
    #define DISPATCH_QUEUE_PRIORITY_LOW (-2)
    #define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
    
    */
}

#pragma mark==dispatch_get_global_queue存在优先级

-(void)pjTestPrioritGlobalQueue{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSLog(@"4");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"3");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"2");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"1");
    });
   //执行顺序为1->2->3->4
 //在指定优先级之后，同一个队列会按照这个优先级执行，打印的顺序为1、2、3、4，当然这不是串行队列，所以不存在绝对回调先后
}

#pragma mark==dispatch_set_target_queue  给自己创建的队列指定优先级

-(void)pjCustomPrioritGlobalQueue{
    
    dispatch_queue_t serialDispatchQueue=dispatch_queue_create("com.PlatoJobs.queue", NULL);
    dispatch_queue_t dispatchgetglobalqueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_set_target_queue(serialDispatchQueue, dispatchgetglobalqueue);
    dispatch_async(serialDispatchQueue, ^{
        NSLog(@"我优先级低，先让让");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"我优先级高,我先block");
    });
    /*我把自己创建的队列塞到了系统提供的global_queue队列中，我们可以理解为：我们自己创建的queue其实是位于global_queue中执行,所以改变global_queue的优先级，也就改变了我们自己所创建的queue的优先级。所以我们常用这种方式来管理子队列。
     */
}

#pragma mark==dispatch_after  用来延迟执行的GCD方法
-(void)pjDispatch_after{
    
    NSLog(@"PlatoJobs1");
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"PlatoJobs2");
    });
    /*
     在主线程，就是刚好延迟了2秒，当然，我说这个2秒并不是绝对的，为什么这么说？还记得我之前在介绍dispatch_async这个特性的时候提到的吗？他的block中方法的执行会放在主线程runloop之后，所以，如果此时runloop周期较长的时候，可能会有一些时差产生。
     
     */
}

#pragma mark==dispatch_group  监听一个并发队列中，所有任务都完成了，就可以用到这个group.
-(void)pjDispatch_group{
    
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group=dispatch_group_create();
    dispatch_group_async(group, queue, ^{NSLog(@"0");});
    dispatch_group_async(group, queue, ^{NSLog(@"1");});
    dispatch_group_async(group, queue, ^{NSLog(@"2");});
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{NSLog(@"完成");});
    
}

#pragma mark-==dispatch_barrier_async
//在并发队列中，完成在它之前提交到队列中的任务后打断，单独执行其block，并在执行完成之后才能继续执行在他之后提交到队列中的任务
-(void)pjDispatch_barrier_async{
    
    dispatch_queue_t concurrentDispatchQueue=dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"0");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"1");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"2");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"3");});
    dispatch_barrier_async(concurrentDispatchQueue, ^{sleep(1); NSLog(@"4");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"5");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"6");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"7");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"8");});
/*
 4之后的任务在我线程sleep之后才执行，这其实就起到了一个线程锁的作用，在多个线程同时操作一个对象的时候，读可以放在并发进行，当写的时候，我们就可以用dispatch_barrier_async方法，效果杠杠的
 */
}

#pragma mark==dispatch_sync

//dispatch_sync 会在当前线程执行队列，并且阻塞当前线程中之后运行的代码，所以，同步线程非常有可能导致死锁现象，我们这边就举一个死锁的例子，直接在主线程调用以下代码：
-(void)pjTestLockDead{
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"死锁");
    });
    
    /*根据FIFO（先进先出）的原则，block里面的代码应该在主线程此次runloop后执行，但是由于他是同步队列，所有他之后的代码会等待其执行完成后才能继续执行，2者相互等待，所以就出现了死锁。*/
}

#pragma mark==同步方法没有去开新的线程，而是在当前线程中执行队列

-(void)pjSync{
    
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{sleep(1);NSLog(@"1");});
    dispatch_sync(queue, ^{sleep(1);NSLog(@"2");});
    dispatch_sync(queue, ^{sleep(1);NSLog(@"3");});
    NSLog(@"4");
    
    // 1->2->3->4
    /*上文说dispatch_get_global_queue不是并发队列，并发队列不是应该会在开启多个线程吗？这个前提是用异步方法。GCD其实是弱化了线程的管理，强化了队列管理，这使我们理解变得比较形象。*/
}

#pragma maark==dispatch_apply  用于无序查找

-(void)pjDispatch_apply{
    
    NSArray *array=[[NSArray alloc]initWithObjects:@"0",@"1",@"2",@"3",@"4",@"5",@"6", nil];
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([array count], queue, ^(size_t index) {
        NSLog(@"%zu=%@",index,[array objectAtIndex:index]);
    });
    NSLog(@"阻塞");
    
    /*
     以下输出结果是可变的
     2019-02-21 12:16:41.404207+0800 GCDPJSt[1096:25859] 0=0
     2019-02-21 12:16:41.404207+0800 GCDPJSt[1096:25901] 2=2
     2019-02-21 12:16:41.404208+0800 GCDPJSt[1096:25903] 1=1
     2019-02-21 12:16:41.404208+0800 GCDPJSt[1096:25902] 3=3
     2019-02-21 12:16:41.404383+0800 GCDPJSt[1096:25859] 4=4
     2019-02-21 12:16:41.404385+0800 GCDPJSt[1096:25903] 6=6
     2019-02-21 12:16:41.404383+0800 GCDPJSt[1096:25901] 5=5
     2019-02-21 12:16:41.404543+0800 GCDPJSt[1096:25859] 阻塞
   
     通过输出log，我们发现这个方法虽然会开启多个线程来遍历这个数组，但是在遍历完成之前会阻塞主线程
     */
    
}

#pragma mark==dispatch_suspend & dispatch_resume  队列挂起和恢复

-(void)pjDispatch_suspendAnddispatch_resume{
    dispatch_queue_t concurrentDispatchQueue=dispatch_queue_create("com.PlatoJobs.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentDispatchQueue, ^{
        
        for (int i=0; i<100; i++)
        {
            NSLog(@"%i",i);
            if (i==50)
            {
                NSLog(@"-----------------------------------");
                dispatch_suspend(concurrentDispatchQueue);
                sleep(3);
                dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_resume(concurrentDispatchQueue);
                });
            }
        }
    });
    //甚至可以在不同的线程对这个队列进行挂起和恢复，因为GCD是对队列的管理
    
}

#pragma mark==Semaphore

-(void)pj_Semaphore{
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);//为了让一次输出10个，初始信号量为10
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i <100; i++)
    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//每进来1次，信号量-1;进来10次后就一直hold住，直到信号量大于0；
        dispatch_async(queue, ^{
            NSLog(@"%i",i);
            sleep(2);
            dispatch_semaphore_signal(semaphore);//由于这里只是log,所以处理速度非常快，我就模拟2秒后信号量+1;
        });
    }
    
    /* 我们可以通过设置信号量的大小，来解决并发过多导致资源吃紧的情况，以单核CPU做并发为例，一个CPU永远只能干一件事情，那如何同时处理多个事件呢，聪明的内核工程师让CPU干第一件事情，一定时间后停下来，存取进度，干第二件事情以此类推，所以如果开启非常多的线程，单核CPU会变得非常吃力，即使多核CPU，核心数也是有限的，所以合理分配线程，变得至关重要，那么如何发挥多核CPU的性能呢？如果让一个核心模拟传很多线程，经常干一半放下干另一件事情，那效率也会变低，所以我们要合理安排，将单一任务或者一组相关任务并发至全局队列中运算或者将多个不相关的任务或者关联不紧密的任务并发至用户队列中运算，所以用好信号量，合理分配CPU资源，程序也能得到优化，当日常使用中，信号量也许我们只起到了一个计数的作用，真的有点大材小用。*/
    
    
}

#pragma mark==dispatch_once

/*  做单例的代码
 
 static SingletonTimer * instance;
 static dispatch_once_t onceToken;
 dispatch_once(&onceToken, ^{
 instance = [[SingletonTimer alloc] init];
 });
 
 return instance;
 
 */


@end
