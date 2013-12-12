from fabric.api import task, cd, run, hosts

@task
@hosts('labuser@qa-dashboard.rd.tandberg.com')
def deploy():
    with cd('~/team_dashboard'):
        run('git pull origin master')
