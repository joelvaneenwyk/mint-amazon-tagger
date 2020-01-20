from threading import Thread
import time

from halo import Halo

# https://stackoverflow.com/questions/4995733/how-to-create-a-spinning-command-line-cursor
# https://github.com/pavdmyt/yaspin
# https://codingdose.info/2019/06/15/how-to-use-a-progress-bar-in-python
# https://pypi.org/project/progress/
# https://pypi.org/project/progressbar2/
# https://pypi.org/project/tqdm/

class AsyncProgress:
    def __init__(self, progress):
        super()
        self.progress = Halo(text=progress, spinner='dots')
        self.spinning = True
        self.timer = Thread(target=self.runnable)
        self.timer.start()

    def runnable(self):
        while self.spinning:
            self.progress.next()
            time.sleep(0.1)

    def finish(self):
        self.spinning = False
        self.progress.finish()
